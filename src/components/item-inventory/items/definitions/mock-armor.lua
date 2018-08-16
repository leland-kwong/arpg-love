local config = require("main.components.items.config")
local utils = require("main.utils")
local itemDefs = require("main.components.items.item-definitions")

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
		sprite = "equipment-armor-1",
		title = 'Mock ARMOR',
		rarity = config.rarity.NORMAL,
		category = config.category.BODY_ARMOR,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return "<color="..color..">"..sign..stat.."</color> <color=white>"..type.."</color>"
			end
			local stats = {
				"<font=body>"..statValue(self.armor, "cyan", "armor").."</font>",
				"<font=body>"..statValue(self.health, "cyan", "health").."</font>"
			}
			local concat = function(separator)
				return function(seed, string, index)
					seed = seed or ""
					local separator = index > 1 and separator or ""
					return seed..separator..string
				end
			end
			return utils.functional.reduce(stats, concat("\n"))
		end,

		getCalculatedProps = function(self)
			return self
		end
	}
})