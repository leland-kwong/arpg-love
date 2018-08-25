local config = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

return itemDefs.registerType({
	type = "mock-shoes",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 20,
			moveSpeed = 250,
			magicResist = 20,
			fireResist = 20
		}
	end,

	properties = {
		sprite = "shoe_5",
		title = 'Mock shoes',
		rarity = config.rarity.NORMAL,
		category = config.category.SHOES,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return {
					color, sign..stat..' ',
					{1,1,1}, type..'\n'
				}
			end
			local stats = {
				statValue(self.armor, Color.CYAN, "armor"),
				statValue(self.moveSpeed, Color.CYAN, "move speed"),
				statValue(self.magicResist, Color.CYAN, "magic resist"),
				statValue(self.fireResist, Color.CYAN, "fire resist")
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,
	}
})