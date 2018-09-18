local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local itemConfig = require 'components.item-inventory.items.config'
local functional = require 'utils.functional'
local itemDefs = require 'components.item-inventory.items.item-definitions'
local msgBus = require 'components.msg-bus'
local AbilityBase = require 'components.abilities.base-class'
local tween = require 'modules.tween'
local config = require 'config.config'

local itemSource = 'H_2_HAMMER'
local healType = 2

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

local function statValue(stat, color, type)
	local sign = stat >= 0 and "+" or "-"
	return {
		color, sign..stat..' ',
		{1,1,1}, type..'\n'
	}
end

local aoeModifiers = {
	armor = -50
}

local function calcDamage(ability)
	return {
		-- physical damage
		damage = math.random(
			ability.minDamage or 0,
			ability.maxDamage or 0
		)
	}
end

local bump = require 'modules.bump'
local hammerWorld = bump.newWorld(4)
local hitModifers = {
	armor = -200
}
local attackTime = 0.3
local attackCooldown = 0
local hitModifierDuration = attackTime * 1.2

local function triggerAttack(self)
	local Position = require 'utils.position'
	local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
	self.dx, self.dy = dx, dy
	local attackPosX, attackPosY = 30 * dx, 30 * dy
	self.collisionX, self.collisionY = self.x - (self.w/2) + attackPosX, self.y - (self.h/2) + attackPosY
	self.collisionW, self.collisionH = self.w, self.h
	local cw = require 'components.collision-worlds'.map
	cw:queryRect(
		self.collisionX,
		self.collisionY,
		self.collisionW,
		self.collisionH,
		function(item)
			if (item.group == 'ai') then
				local aiCollision = item
				local aiCollisionX, aiCollisionY = aiCollision:getPositionWithOffset()
				hammerWorld:add(
					item.parent,
					aiCollisionX,
					aiCollisionY,
					aiCollision.w,
					aiCollision.h
				)
				return true
			end
		end
	)
	hammerWorld:queryRect(
		self.collisionX,
		self.collisionY,
		self.collisionW,
		self.collisionH,
		function(item)
			msgBus.send(msgBus.CHARACTER_HIT, {
				parent = item,
				damage = calcDamage(self)
			})
			-- attack modifier
			msgBus.send(msgBus.CHARACTER_HIT, {
				parent = item,
				duration = hitModifierDuration,
				modifiers = hitModifers,
				source = itemSource
			})
		end
	)

	local itemsAddedToWorld, len = hammerWorld:getItems()
	for i=1, len do
		hammerWorld:remove(itemsAddedToWorld[i])
	end
end

local function angleFromDirection(dx, dy, startAngle)
	return (math.atan2(dx, dy) * -1) + startAngle
end

local setupChanceFunctions = require 'utils.chance'
local genFloorCrackStyle = setupChanceFunctions({
	{
		chance = 1,
		__call = function()
			return 'floor-crack-1'
		end
	},
	{
		chance = 1,
		__call = function()
			return 'floor-crack-2'
		end
	},
	{
		chance = 1,
		__call = function()
			return 'floor-crack-3'
		end
	}
})

local function drawFloorCrack(style, x, y, angle)
	local AnimationFactory = require 'components.animation-factory'
	local floorCrackSprite = AnimationFactory:newStaticSprite(style)
	local ox, oy = floorCrackSprite:getSourceOffset()
	love.graphics.draw(
		AnimationFactory.atlas,
		floorCrackSprite.sprite,
		x, y,
		angle,
		1, 1,
		ox, oy
	)
end

local Fissure = Component.createFactory(
	AbilityBase({
		group = groups.all,
		minDamage = 3,
		maxDamage = 5,
		weaponDamageScaling = 1.3,
		width = 10,
		speed = 250,
		lifeTime = 0,
		maxAnimationLifeTime = 1,
		maxWallLifeTime = 2,
		init = function(self)
			self.crackSize = 32
			local collisionWorlds = require 'components.collision-worlds'
			local collisionSize = self.crackSize
			self.collision = self:addCollisionObject(
				'PROJECTILE',
				self.x,
				self.y,
				collisionSize,
				collisionSize
			):addToWorld(collisionWorlds.map)
			local Position = require 'utils.position'
			self.dx, self.dy = Position.getDirection(self.x, self.y, self.x2, self.y2)

			self.floorCrackStyles = {}
			for i=1, 4 do
				table.insert(self.floorCrackStyles, genFloorCrackStyle())
			end

			local shockWaveDistance = (#self.floorCrackStyles + 1) * self.crackSize
			local finalX = self.x + self.dx * shockWaveDistance
			local finalY = self.y + self.dy * shockWaveDistance
			self.collision:move(finalX, finalY, function(item, other)
				if other.group == 'ai' then
					msgBus.send(msgBus.CHARACTER_HIT, {
						parent =  other.parent,
						damage = calcDamage(self)
					})
					return 'touch'
				end
			end)
		end,
		update = function(self, dt)
			self.lifeTime = self.lifeTime + dt
			if self.lifeTime > self.maxAnimationLifeTime then
				self:delete()
			end
		end,
		draw = function(self)
			local crackStyles = self.floorCrackStyles
			love.graphics.setColor(0,0,0,0.8)
			for i=1, #crackStyles do
				local dist = self.crackSize * i
				drawFloorCrack(
					crackStyles[i],
					self.x + dist * self.dx,
					self.y + dist * self.dy,
					angleFromDirection(self.dx, self.dy, math.pi/2)
				)
			end
		end
	})
)

local Attack = Component.createFactory(
	AbilityBase({
		group = groups.all,
		minDamage = 4,
		maxDamage = 6,
		weaponDamageScaling = 1.2,
		w = 40,
		h = 40,
		impactAnimationDuration = 0.4,
		cooldown = attackCooldown,
		opacity = 1,
		init = function(self)
			self.animationTween = tween.new(self.impactAnimationDuration, self, { opacity = 0 }, tween.easing.inExpo)

			Fissure.create({
				x = self.x,
				y = self.y,
				x2 = self.x2,
				y2 = self.y2
			})
		end,
		update = function(self, dt)
			-- we must trigger after init since the attack gets modified immediately upon creation
			if (not self.triggered) then
				triggerAttack(self)
				self.triggered = true
			end
			local complete = self.animationTween:update(dt)
			if complete then
				self:delete()
			end
		end,
		draw = function(self)
			love.graphics.setColor(
				Color.rgba255(244, 177, 70, 0.3 * self.opacity)
			)
			love.graphics.rectangle('fill',
				self.collisionX,
				self.collisionY,
				self.collisionW,
				self.collisionH
			)
		end,
		drawOrder = function(self)
			return 1
		end
	})
)

local function handleUpgrade1(self)
	local upgrades = itemDefs.getDefinition(self).upgrades
	local up1 = upgrades[1]
	local state = itemDefs.getState(self)
	if state.forceField then
		return
	end
	local ForceField = require 'components.item-inventory.items.definitions.pod-module-hammer.force-field'
	local playerRef = Component.get('PLAYER')
	state.forceField = ForceField.create({
		x = playerRef.x,
		y = playerRef.y,
		size = 17,
		maxShieldHealth = 30,
		unhitDurationRequirement = 1.5,
		drawOrder = function()
			return playerRef:drawOrder() + 3
		end
	}):setParent(playerRef)
end

return itemDefs.registerType({
	type = 'pod-module-hammer',

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			healthRegeneration = 2,
			maxHealth = 10,
			weaponDamage = 2,
			experience = 0
		}
	end,

	properties = {
		sprite = "weapon-module-hammer",
		title = 'h-2 hammer',
		rarity = itemConfig.rarity.NORMAL,
		category = itemConfig.category.POD_MODULE,

		levelRequirement = 1,
		attackTime = attackTime,
		energyCost = function(self)
			return 2
		end,

		upgrades = {
			{
				title = 'force field',
				description = '',
				experienceRequired = 0,
				props = {
					duration = 99999,
					shieldHealth = 100
				},
			},
			{
				title = 'fissure',
				description = '',
				experienceRequired = 0,
				props = {},
			}
		},

		onEquip = function(self)
			local duration = math.pow(10, 10)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = self.healthRegeneration * duration,
				duration = duration,
				source = itemSource,
				type = healType,
				property = 'health',
				maxProperty = 'maxHealth'
			})
			msgBus.send(msgBus.PLAYER_WEAPON_RENDER_ATTACHMENT_ADD, {
				animationFrames = {'weapon-hammer-attachment'}
			})
			msgBus.subscribe(function(msgType, msgValue)
				if (msgBus.ITEM_UPGRADE_UNLOCKED == msgType)
					and (msgValue.item == self)
				then
					if (msgValue.level == 1) then
						handleUpgrade1(self)
					end
					if (msgValue.level == 2) then
						itemDefs.getState(self).level2Ready = true
					end
				end
			end)
		end,

		final = function(self)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_REMOVE, {
				source = itemSource,
			})
			msgBus.send(msgBus.PLAYER_WEAPON_RENDER_ATTACHMENT_REMOVE)
			if self.forceField then
				self.forceField:delete()
			end
		end,

		tooltip = function(self)
			return {
				Color.YELLOW, '\nactive skill:\n',
				Color.WHITE, 'deals ',
				Color.CYAN, Attack.minDamage ..'-'.. Attack.maxDamage,
				Color.WHITE, " damage at a target area in front of you. Each hit reduces the target's armor by ",
				Color.CYAN, hitModifers.armor,
				Color.WHITE, ' for ',
				Color.CYAN, hitModifierDuration,
				Color.WHITE, ' seconds'
			}
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local sound = love.audio.newSource(
				'built/sounds/mechanical-hammer.wav',
				'static'
			)
			sound:setVolume(0.65)
			love.audio.play(sound)
			return Attack.create(props)
		end
	}
})