local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local functional = require 'utils.functional'
local msgBus = require 'components.msg-bus'
local AbilityBase = require 'components.abilities.base-class'
local tween = require 'modules.tween'
local collisionGroups = require 'modules.collision-groups'
local config = require 'config.config'
local filter = require 'utils.filter-call'
local itemSystem = require(require('alias').path.itemSystem)

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
			if (collisionGroups.matches(item.group, collisionGroups.create(collisionGroups.ai, collisionGroups.environment))) then
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
			local Position = require 'utils.position'
			self.dx, self.dy = Position.getDirection(self.x, self.y, self.x2, self.y2)

			self.crackSize = 32
			local collisionWorlds = require 'components.collision-worlds'
			local collisionSize = self.crackSize
			self.collision = self:addCollisionObject(
				collisionGroups.projectile,
				self.x,
				self.y,
				collisionSize,
				collisionSize,
				self.crackSize/2,
				self.crackSize/2
			):addToWorld(collisionWorlds.map)

			self.floorCrackStyles = {}
			for i=1, 4 do
				table.insert(self.floorCrackStyles, genFloorCrackStyle())
			end

			local shockWaveDistance = (#self.floorCrackStyles) * self.crackSize
			local finalX = self.x + self.dx * shockWaveDistance
			local finalY = self.y + self.dy * shockWaveDistance
			self.collision:move(finalX, finalY, function(item, other)
				if collisionGroups.matches(other.group, collisionGroups.create(collisionGroups.ai, collisionGroups.environment)) then
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
			local opacity = 1 - (self.lifeTime / self.maxAnimationLifeTime)
			local crackStyles = self.floorCrackStyles
			love.graphics.setColor(0,0,0,0.3 * opacity)
			for i=1, #crackStyles do
				local dist = self.crackSize * i
				drawFloorCrack(
					crackStyles[i],
					self.x + dist * self.dx,
					self.y + dist * self.dy - 2,
					angleFromDirection(self.dx, self.dy, math.pi/2)
				)
			end

			love.graphics.setColor(0,0,0,0.8 * opacity)
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
		minDamage = 5,
		maxDamage = 8,
		weaponDamageScaling = 1.2,
		w = 40,
		h = 40,
		impactAnimationDuration = 0.4,
		cooldown = attackCooldown,
		opacity = 1,
		init = function(self)
			self.animationTween = tween.new(self.impactAnimationDuration, self, { opacity = 0 }, tween.easing.inExpo)
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

return itemSystem.registerModule({
  name = 'aoe-slam',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    return {
      blueprint = Attack
    }
  end
})
