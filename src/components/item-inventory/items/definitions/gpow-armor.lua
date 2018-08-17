local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local msgBus = require("components.msg-bus")

local category = config.category.BODY_ARMOR

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
	type = "GPOW",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 100,
			maxHealth = 200,
		}
	end,

	properties = {
		sprite = "armor_16",
		title = 'Godly Plate of the Whale',
		rarity = config.rarity.EPIC,
		category = category,

		onActivate = function(self)
			msgBus.send(msgBus.EQUIPMENT_SWAP, {
				self,
				category,
			})
		end,

		tooltip = function(self)
			local stats = {
				statValue(self.armor, Color.CYAN, "armor"),
				statValue(self.maxHealth, Color.CYAN, "maximum health"),
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end
	}
})