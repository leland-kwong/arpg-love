local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemSystem =require("components.item-inventory.items.item-system")
local Color = require('modules.color')
local msgBus = require 'components.msg-bus'
local Aoe = require 'components.abilities.aoe'

local healSource = "X_1_TIME_BENDER"
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
	moveSpeed = function(target)
		return target.moveSpeed * -0.35
	end
}

local function aoeOnHit(self)
	return {
		duration = 2,
		modifiers = aoeModifiers,
		statusIcon = 'status-slow',
		source = 'DEBUFF_SLOW'
	}
end

return itemSystem.registerType({
	type = 'pod-module-slow-time',

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			healthRegeneration = 2,
			maxHealth = 10
		}
	end,

	properties = {
		sprite = "weapon-module-slow-time",
		title = 'x-1 time-bender',
		rarity = config.rarity.EPIC,
		baseDropChance = 1,
		category = config.category.POD_MODULE,

		levelRequirement = 4,
		energyCost = function(self)
			return 2
		end,

		onEquip = function(self)
			local duration = math.pow(10, 10)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = self.healthRegeneration * duration,
				duration = duration,
				source = healSource,
				type = healType,
				property = 'health',
				maxProperty = 'maxHealth'
			})
		end,

		final = function(self)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_REMOVE, {
				source = healSource,
			})
		end,

		tooltip = function(self)
			return {
				Color.YELLOW, 'active skill:\n',
				Color.WHITE, 'slows enemies in an area around a target position'
			}
		end,

		onActivate = function(self)
			local toSlot = itemSystem.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local Sound = require 'components.sound'
			love.audio.stop(Sound.SLOW_TIME)
			love.audio.play(Sound.SLOW_TIME)

			return Aoe.create(
				props
					:set('area', 100)
					:set('targetGroup', 'ai')
					:set('onHit', aoeOnHit)
			)
		end
	}
})