local Component = require 'modules.component'
local itemConfig = require("components.item-inventory.items.config")
local gameConfig = require 'config.config'
local msgBus = require("components.msg-bus")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require 'modules.color'
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local setProp = require 'utils.set-prop'
local Sound = require 'components.sound'
local memoize = require 'utils.memoize'
local LOS = memoize(require 'modules.line-of-sight')
local extend = require 'utils.object-utils'.extend

local bulletColor = {Color.rgba255(252, 122, 255)}

local function statValue(stat, color, type)
	local sign = stat >= 0 and "+" or "-"
	return {
		color, sign..stat..' ',
		{1,1,1}, type
	}
end

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

local upgrades = {
	{
		sprite = 'item-upgrade-placeholder-unlocked',
		title = 'Shock',
		description = 'Attacks shock the target, dealing 1-2 lightning damage.',
		experienceRequired = 10,
		props = {
			shockDuration = 0.4,
			minLightningDamage = 1,
			maxLightningDamage = 2
		}
	},
	{
		sprite = 'item-upgrade-placeholder-unlocked',
		title = 'Critical Strikes',
		description = 'Attacks have a 25% chance to deal 1.2 - 1.4x damage',
		experienceRequired = 40,
		props = {
			minCritMultiplier = 0.2,
			maxCritMultiplier = 0.4,
			critChance = 0.25
		}
	},
	{
		sprite = 'item-upgrade-placeholder-unlocked',
		title = 'Ricochet',
		description = 'Attacks bounce to 2 other targets, dealing 50% less damage each bounce.',
		experienceRequired = 120
	}
}

local weaponLength = 26
local weaponCooldown = 0.1

local function CreateAttack(self, props)
	local Projectile = require 'components.abilities.bullet'
	local numBounces = props.numBounces and (props.numBounces + 1) or 0
	return Projectile.create(
		setProp(props)
			:set('maxBounces', 1)
			:set('numBounces', numBounces)
			:set('minDamage', 1)
			:set('maxDamage', 3)
			:set('color', bulletColor)
			:set('targetGroup', 'ai')
			:set('startOffset', weaponLength)
			:set('speed', 400)
			:set('cooldown', weaponCooldown)
			:set('onHit', itemDefs.getState(self).onHit)
	)
end

local muzzleFlashMessage = {
	color = bulletColor
}

return itemDefs.registerType({
	type = "pod-module-initiate",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			-- static properties
			weaponDamage = 1,
			experience = 0
		}
	end,

	properties = {
		sprite = "weapon-module-initiate",
		title = 'r-1 initiate',
		rarity = itemConfig.rarity.NORMAL,
		category = itemConfig.category.POD_MODULE,

		attackTime = weaponCooldown - 0.01,
		energyCost = function(self)
			return 1
		end,

		tooltip = function(self)
			local stats = {
				statValue(self.weaponDamage, Color.CYAN, "damage \n")
			}
			return functional.reduce(stats, concatTable, {})
		end,

		tooltipItemUpgrade = function(self)
			return upgrades
		end,

		onEquip = function(self)
			local function getHighestUpgradeUnlocked()
				local highestUpgradeUnlocked = 0
				for i=1, #upgrades do
					local up = upgrades[i]
					if self.experience >= up.experienceRequired then
						highestUpgradeUnlocked = i
					end
				end
				return highestUpgradeUnlocked
			end

			local lastUpgradeUnlocked = getHighestUpgradeUnlocked()

			local msgTypes = {
				[msgBus.EQUIPMENT_UNEQUIP] = function(v)
					return msgBus.CLEANUP
				end,
				[msgBus.ENEMY_DESTROYED] = function(v)
					self.experience = self.experience + v.experience
					local nextUpgradeLevel = getHighestUpgradeUnlocked()
					local newUpgradeUnlocked = nextUpgradeLevel > lastUpgradeUnlocked
					lastUpgradeUnlocked = nextUpgradeLevel
					if newUpgradeUnlocked then
						local itemTitle = itemDefs.getDefinition(self).title
						msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
							title = itemTitle..' upgraded',
							icon = itemDefs.getDefinition(self).sprite,
							description = {
								Color.CYAN, upgrades[nextUpgradeLevel].title,
								Color.WHITE, ' is unlocked'
							}
						})
					end
				end
			}

			msgBus.subscribe(function(msgType, msgValue)
				local handler = msgTypes[msgType]
				if handler then
					handler(msgValue)
				end
			end)

			local state = itemDefs.getState(self)
			state.onHit = function(attack, hitMessage)
				local up1 = upgrades[1]
				local up1Ready = self.experience >= up1.experienceRequired
				if up1Ready then
					msgBus.send(msgBus.CHARACTER_HIT, {
						parent = hitMessage.parent,
						duration = up1.props.shockDuration,
						modifiers = {
							shocked = 1
						},
						source = 'INITIATE_SHOCK'
					})
					love.audio.stop(Sound.ELECTRIC_SHOCK_SHORT)
					love.audio.play(Sound.ELECTRIC_SHOCK_SHORT)

					hitMessage.lightningDamage = math.random(
						up1.props.minLightningDamage,
						up1.props.maxLightningDamage
					)
				end

				local up2 = upgrades[2]
				local up2Ready = self.experience >= up2.experienceRequired
				if up2Ready then
					hitMessage.criticalChance = up2.props.critChance
					hitMessage.criticalMultiplier = math.random(
						up2.props.minCritMultiplier * 100,
						up2.props.maxCritMultiplier * 100
					) / 100
				end

				local up3 = upgrades[3]
				local up3Ready = self.experience >= up3.experienceRequired
				if up3Ready then
					if attack.numBounces >= attack.maxBounces then
						return hitMessage
					end
					local findNearestTarget = require 'modules.find-nearest-target'
					local currentTarget = hitMessage.parent

					local mainSceneRef = Component.get('MAIN_SCENE')
					local mapGrid = mainSceneRef.mapGrid
					local gridSize = gameConfig.gridSize
					local Map = require 'modules.map-generator.index'
					local losFn = LOS(mapGrid, Map.WALKABLE)

					local target = findNearestTarget(
						currentTarget.collisionWorld,
						{currentTarget},
						currentTarget.x,
						currentTarget.y,
						6 * gridSize,
						losFn,
						gridSize
					)
					if target then
						local props = extend(attack, {
							x = currentTarget.x,
							y = currentTarget.y,
							x2 = target.x,
							y2 = target.y
						})
						CreateAttack(self, props)
					end
				end

				return hitMessage
			end
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			love.audio.stop(Sound.PLASMA_SHOT)
			love.audio.play(Sound.PLASMA_SHOT)
			msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)
			return CreateAttack(self, props)
		end
	}
})