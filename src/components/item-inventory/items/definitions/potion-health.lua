local config = require("components.item-inventory.items.config")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local msgBus = require("components.msg-bus")
local Sound = require 'components.sound'
local socket = require 'socket'

return itemDefs.registerType({
	type = "potion-health",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			minHeal = 80,
			maxHeal = 100,
			duration = 2,
			source = 'HEALTH_POTION_'..socket.gettime()
		}
	end,

	properties = {
		sprite = "potion_48",
		title = "Potion of Healing",
		rarity = config.rarity.NORMAL,
		category = config.category.CONSUMABLE,

		onActivate = function(self, mainState)
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self)
			msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
				amount = math.random(self.minHeal, self.maxHeal),
				source = self.source,
				duration = self.duration,
				property = 'health',
				maxProperty = 'maxHealth'
			})
			love.audio.stop(Sound.drinkPotion)
			love.audio.play(Sound.drinkPotion)
			return {
				cooldown = self.duration
			}
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