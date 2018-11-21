local config = require("components.item-inventory.items.config")
local itemSystem =require("components.item-inventory.items.item-system")
local Color = require 'modules.color'
local setProp = require 'utils.set-prop'

local mathFloor = math.floor

local baseDamage = 1

return {
	type = "lightning-rod",

	blueprint = {
		info = {},
	},

	properties = {
		sprite = "weapon-module-lightning-rod",
		title = 'The lightning rod',
		baseDropChance = 1,
		category = config.category.POD_MODULE,
	}

	-- 	attackTime = 0.1,
	-- 	energyCost = function(self)
	-- 		return 4
	-- 	end,

	-- 	tooltip = function(self)
	-- 		local _state = self.state
	-- 		local stats = {
	-- 			{
  --         Color.YELLOW, '\nactive skill:\n\n',
  --         Color.WHITE, 'Deals ',
  --         Color.CYAN, self.weaponDamage,
  --         Color.WHITE, ' damage, bouncing to up to 3 targets'
	-- 			}
	-- 		}
	-- 		return functional.reduce(stats, function(combined, textObj)
	-- 			return concatTable(combined, textObj)
	-- 		end, {})
	-- 	end,

	-- 	onActivate = function(self)
	-- 		local toSlot = itemSystem.getDefinition(self).category
	-- 		msgBus.send(msgBus.EQUIPMENT_SWAP, self)
	-- 	end,

	-- 	onActivateWhenEquipped = function(self, props)
	-- 		local Attack = require 'components.abilities.chain-lightning'
	-- 		local Sound = require 'components.sound'
	-- 		local soundSource = Sound.ENERGY_BEAM
	-- 		soundSource:setFilter {
	-- 			type = 'lowpass',
	-- 			volume = .6,
	-- 		}
	-- 		love.audio.stop(Sound.ENERGY_BEAM)
	-- 		love.audio.play(Sound.ENERGY_BEAM)
	-- 		return Attack.create(
  --       setProp(props)
	-- 				:set('targetGroup', 'ai')
	-- 				:set('startOffset', 26)
  --     )
	-- 	end
	-- }
}