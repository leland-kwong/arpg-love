local Audio = require("main.audio.audio")
local config = require("main.components.items.config")
local itemDefs = require("main.components.items.item-definitions")

return itemDefs.registerType({
	type = "EXPERIENCE_POTION",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 99,

			minExpGain = 5,
			maxExpGain = 8
		}
	end,

	properties = {
		sprite = "potion-white-1",
		title = 'Potion of experience',
		rarity = config.rarity.NORMAL,
		category = config.category.CONSUMABLE,
		
		onActivate = function(self, playerState, inventoryState)
			playerState:set('exp', function(state)
				local amount = math.random(self.minExpGain, self.maxExpGain)
				return state.exp + amount
			end)
			playerState:removeItem(self)

			Audio.play(Audio.POTION)
		end
	}
})