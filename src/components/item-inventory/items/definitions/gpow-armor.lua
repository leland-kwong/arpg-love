local Audio = require("main.audio.audio")
local config = require("main.components.items.config")
local utils = require("main.utils")
local itemDefs = require("main.components.items.item-definitions")
local msgBus = require("main.state.msg-bus")

local category = config.category.BODY_ARMOR

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
		sprite = "equipment-armor-1",
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
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return "<color="..color..">"..sign..stat.."</color> <color=white>"..type.."</color>"
			end
			local stats = {
				"<font=body>"..statValue(self.armor, "cyan", "armor").."</font>",
				"<font=body>"..statValue(self.maxHealth, "cyan", "maximum health").."</font>"
			}
			local concat = function(separator)
				return function(seed, string, index)
					seed = seed or ""
					local separator = index > 1 and separator or ""
					return seed..separator..string
				end
			end
			return utils.functional.reduce(stats, concat("\n"))
		end
	}
})