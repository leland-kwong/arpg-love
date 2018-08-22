local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local msgBus = require("components.msg-bus")
local Sound = require 'components.sound'

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
		sprite = "potion_48",
		title = "Potion of Healing",
		rarity = config.rarity.NORMAL,
		category = config.category.CONSUMABLE,

		onActivate = function(self, mainState)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = math.random(self.minHeal, self.maxHeal),
				source = self.source,
				duration = self.duration,
			})
			mainState:removeItem(self)
			love.audio.stop(Sound.drinkPotion)
			love.audio.play(Sound.drinkPotion)
		end,

		tooltip = function(self)
			local timeUnit = self.duration > 1 and "seconds" or "second"
			local tooltipString = {
				Color.WHITE, 'Restores ',
				Color.LIME, self.minHeal .. '-' .. self.maxHeal .. ' health ',
				Color.WHITE, 'over ',
				Color.CYAN, self.duration .. ' ' .. timeUnit
			}
			return tooltipString
		end
	}
})