local config = require("main.components.items.config")
local msgBus = require("main.state.msg-bus")
local functional = require("utils.functional")
local itemDefs = require("main.components.items.item-definitions")

return itemDefs.registerType({
	type = "ICE_CLIMBERS",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 20,
			moveSpeed = 100,
		}
	end,

	properties = {
		sprite = "shoes-2",
		title = 'Ice Climbers',
		rarity = config.rarity.RARE,
		category = config.category.SHOES,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return "<color="..color..">"..sign..stat.."</color> <color=white>"..type.."</color>"
			end
			local stats = {
				"<font=body>"..statValue(self.armor, "cyan", "armor").."</font>",
				"<font=body>"..statValue(self.moveSpeed, "cyan", "move speed").."</font>"
			}
			local concat = function(separator)
				return function(seed, string, index)
					seed = seed or ""
					local separator = index > 1 and separator or ""
					return seed..separator..string
				end
			end
			return functional.reduce(stats, concat("\n"))
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, {
				self,
				toSlot,
			})
		end,
	}
})