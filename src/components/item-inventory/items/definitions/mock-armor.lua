local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local msgBus = require 'components.msg-bus'

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

return itemDefs.registerType({
	type = "MOCK_ARMOR",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 100,
			maxHealth = 200,
			moveSpeed = 10,
			damage = 5
		}
	end,

	properties = {
		sprite = "armor_62",
		title = 'Mock ARMOR',
		rarity = config.rarity.NORMAL,
		category = config.category.BODY_ARMOR,

		onActivate = function(self, rootStore)
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

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
				statValue(self.maxHealth, Color.CYAN, "maximum health"),
				statValue(self.moveSpeed, Color.CYAN, "move speed"),
				statValue(self.damage, Color.CYAN, "damage"),
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end,

		getCalculatedProps = function(self)
			return self
		end
	}
})