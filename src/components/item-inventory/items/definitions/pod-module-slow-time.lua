local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
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

return itemDefs.registerType({
	type = 'pod-module-slow-time',

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			regeneration = 2,
			maxHealth = 10
		}
	end,

	properties = {
		sprite = "weapon-module-slow-time",
		title = 'x-1 time-bender',
		rarity = config.rarity.EPIC,
		category = config.category.POD_MODULE,

		levelRequirement = 4,
		energyCost = function(self)
			return 2
		end,

		onEquip = function(self)
			local duration = math.pow(10, 10)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = self.regeneration * duration,
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
			local stats = {
				statValue(self.regeneration, Color.CYAN, "health regeneration per second"),
				statValue(self.maxHealth, Color.CYAN, "maximum health"),
			}
			return functional.reduce(stats, concatTable, {})
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
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