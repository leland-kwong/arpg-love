local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local msgBus = require 'components.msg-bus'

local healSource = "ION_GENERATOR_2"
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

return itemDefs.registerType({
	type = "ION_GENERATOR_2",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			regeneration = 2,
			maxHealth = 10
		}
	end,

	properties = {
		sprite = "book_1",
		title = 'Ion Generator',
		rarity = config.rarity.NORMAL,
		category = config.category.SIDE_ARM,

		onEquip = function(self)
			local duration = math.pow(10, 10)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = self.regeneration * duration,
				duration = duration,
				source = healSource,
				type = healType
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
	}
})