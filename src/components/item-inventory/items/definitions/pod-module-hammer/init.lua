local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local itemConfig = require 'components.item-inventory.items.config'
local functional = require 'utils.functional'
local itemDefs = require 'components.item-inventory.items.item-definitions'
local msgBus = require 'components.msg-bus'
local AbilityBase = require 'components.abilities.base-class'
local tween = require 'modules.tween'
local collisionGroups = require 'modules.collision-groups'
local config = require 'config.config'
local filter = require 'utils.filter-call'

local itemSource = 'H_2_HAMMER'
local healType = 2

return {
	type = 'pod-module-hammer',

	blueprint = {
		props = {

		},

		baseModifiers = {
			healthRegeneration = {2, 2},
			maxHealth = {10, 10},
			weaponDamage = {2, 2},
			energyCost = 2,
			experience = 0
		}
	},

	properties = {
		sprite = "weapon-module-hammer",
		title = 'h-2 hammer',
		rarity = itemConfig.rarity.NORMAL,
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		levelRequirement = 1,
		attackTime = attackTime,

		renderAnimation = 'weapon-hammer-attachment',

		upgrades = {
			{
				title = 'force field',
				description = '',
				experienceRequired = 10,
				props = {
					duration = 99999,
					shieldHealth = 100
				},
			},
			{
				title = 'fissure',
				description = '',
				experienceRequired = 40,
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

			local state = itemDefs.getState(self)
			state.forceField = state.forceField or setupForceField():setDisabled(true)
			state.listeners = {
				msgBus.on(msgBus.ITEM_UPGRADE_UNLOCKED, filter(function(v)
					state.forceField:setDisabled(false)
				end, function(v)
					return v.item == self and v.level == 1
				end))
			}
		end,

		final = function(self)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_REMOVE, {
				source = itemSource,
			})
			local state = itemDefs.getState(self)
			if state.forceField then
				state.forceField:delete()
			end
			msgBus.off(state.listeners)
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

			local isUpgrade2Available = msgBus.send(
				msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, {
					item = self,
					level = 2
				}
			)

			if isUpgrade2Available then
				Fissure.create({
					x = props.x,
					y = props.y,
					x2 = props.x2,
					y2 = props.y2
				})
			end

			return Attack.create(props)
		end
	}
}