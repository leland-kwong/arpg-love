local Component = require 'modules.component'
local config = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local functional = require("utils.functional")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require('modules.color')
local tick = require('utils.tick')
local Sound = require 'components.sound'

local speedBoostSoundFilter = {
  type = 'lowpass',
  volume = .5,
}

return itemDefs.registerType({
	type = "mock-shoes",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 20,
			moveSpeed = 100,
			fireResist = 20,

			speedBoost = 300,
			speedBoostDuration = 1
		}
	end,

	properties = {
		sprite = "shoe_5",
		title = 'Mock shoes',
		rarity = config.rarity.NORMAL,
		category = config.category.SHOES,

		tooltip = function(self)
			return {
				Color.YELLOW, '\nactive skill:\n\n',
				Color.WHITE, 'Gain ',
				Color.LIME, self.speedBoost..' extra move speed',
				Color.WHITE, ' for ',
				Color.CYAN, self.speedBoostDuration..' seconds'
			}
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self)
			Sound.MOVE_SPEED_BOOST:setFilter(speedBoostSoundFilter)
			love.audio.stop(Sound.MOVE_SPEED_BOOST)
			love.audio.play(Sound.MOVE_SPEED_BOOST)
			local buffDuration = self.speedBoostDuration
			msgBus.send(msgBus.CHARACTER_HIT, {
				parent = Component.get('PLAYER'),
				duration = buffDuration,
				modifiers = {
					moveSpeed = self.speedBoost
				},
				source = 'MOCK_SHOES'
			})
			return {
				cooldown = buffDuration
			}
		end
	}
})