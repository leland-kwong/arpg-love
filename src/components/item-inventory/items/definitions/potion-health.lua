local Audio = require("main.audio.audio")
local itemConfig = require("main.components.items.config")
local itemDefs = require("main.components.items.item-definitions")
local msgBus = require("main.state.msg-bus")

return itemDefs.registerType({
	type = "HEALTH_POTION",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 99,

			minHeal = 80,
			maxHeal = 100,
			duration = 3,
			source = 'HEALTH_POTION'
		}
	end,

	properties = {
		sprite = "potion-red-4",
		title = "Potion of Healing",
		rarity = itemConfig.rarity.NORMAL,
		category = itemConfig.category.CONSUMABLE,

		onActivate = function(self, mainState)
			msgBus.send(msgBus.PLAYER_ADD_HEAL_SOURCE, {
				amount = math.random(self.minHeal, self.maxHeal),
				source = self.source,
				duration = self.duration,
				type = 1
			})
			mainState:removeItem(self)
			Audio.play(Audio.POTION)
		end,

		tooltip = function(self)
			local timeUnit = self.duration > 1 and "seconds" or "second"
			local duration = "<color=cyan>"..self.duration.."</color> "..timeUnit
			local body = "<font=body>Restores <color=lime>+"..self.minHeal.."-"..self.maxHeal.." health</color> over "..duration.."</font>"
			return body
		end
	}
})