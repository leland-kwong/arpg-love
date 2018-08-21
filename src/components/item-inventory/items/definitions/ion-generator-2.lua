local config = require("main.components.items.config")
local utils = require("main.utils")
local itemDefs = require("main.components.items.item-definitions")
local msgBus = require("main.state.msg-bus")

local healSource = "ION_GENERATOR"
local healType = 2

return itemDefs.registerType({
	type = "ION_GENERATOR_2",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			regeneration = 6,
			maxHealth = 10
		}
	end,

	properties = {
		sprite = "ion-generator-2",
		title = 'Ion Generator 2',
		rarity = config.rarity.NORMAL,
		category = config.category.ION_GENERATOR,

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
			-- replace source with a 0 healing source
			msgBus.send(msgBus.PLAYER_REMOVE_HEAL_SOURCE, {
				source = healSource,
			})
		end,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return "<color="..color..">"..sign..stat.."</color> <color=white>"..type.."</color>"
			end
			local stats = {
				"<font=body>"..statValue(self.regeneration, "cyan", "ion regeneration per second").."</font>",
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