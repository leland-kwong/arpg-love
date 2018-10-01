local Component = require 'modules.component'
local itemConfig = require("components.item-inventory.items.config")
local gameConfig = require 'config.config'
local msgBus = require("components.msg-bus")
local itemSystem =require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local memoize = require 'utils.memoize'
local LOS = memoize(require 'modules.line-of-sight')
local extend = require 'utils.object-utils'.extend

local weaponCooldown = 0.1

return {
	type = "pod-module-initiate",

	instanceProps = {
		props = {
			weaponCooldown = weaponCooldown,
			attackTime = weaponCooldown - 0.01
		},

		baseModifiers = {
			weaponDamage = {1, 1},
			energyCost = {1, 1}
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click'),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.plasma-shot')
	},

	properties = {
		sprite = "weapon-module-initiate",
		title = 'r-1 initiate',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		tooltipItemUpgrade = function(self)
			return upgrades
		end,

		upgrades = {
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
		},

		onEquip = function(self)
			local state = itemSystem.getState(self)
			local definition = itemSystem.getDefinition(self)
			local upgrades = definition.upgrades
			state.onHit = function(attack, hitMessage)
				local up1 = upgrades[1]
				local up1Ready = msgBus.send(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, {
					item = self,
					level = 1
				})
				if up1Ready then
					msgBus.send(msgBus.CHARACTER_HIT, {
						parent = hitMessage.parent,
						duration = up1.props.shockDuration,
						modifiers = {
							shocked = 1
						},
						source = 'INITIATE_SHOCK'
					})
					hitMessage.lightningDamage = math.random(
						up1.props.minLightningDamage,
						up1.props.maxLightningDamage
					)
				end

				local up2Ready = msgBus.send(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, {
					item = self,
					level = 2
				})
				if up2Ready then
					local up2 = upgrades[2]
					hitMessage.criticalChance = up2.props.critChance
					hitMessage.criticalMultiplier = math.random(
						up2.props.minCritMultiplier * 100,
						up2.props.maxCritMultiplier * 100
					) / 100
				end

				local up3Ready = msgBus.send(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, {
					item = self,
					level = 3
				})
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
		end
	}
}