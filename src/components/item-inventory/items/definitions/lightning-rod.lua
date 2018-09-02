local config = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require 'modules.color'
local functional = require("utils.functional")
local setProp = require 'utils.set-prop'

local mathFloor = math.floor

local baseDamage = 2

local function statValue(stat, color, type)
	local sign = stat >= 0 and "+" or "-"
	return {
		color, sign..stat..' ',
		{1,1,1}, type
	}
end

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

return itemDefs.registerType({
	type = "lightning-rod",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			-- static properties
			weaponDamage = baseDamage,
		}
	end,

	properties = {
		sprite = "magicweapon_24",
		title = 'The lightning rod',
		rarity = config.rarity.LEGENDARY,
		category = config.category.WEAPON_1,

		energyCost = function(self)
			return 2
		end,

		tooltip = function(self)
			local _state = self.state
			local stats = {
				{
          Color.YELLOW, '\nactive skill:\n\n',
          Color.WHITE, 'Deals ',
          Color.CYAN, self.weaponDamage,
          Color.WHITE, ' damage, bouncing to up to 3 targets'
				}
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local Attack = require 'components.abilities.chain-lightning'
			return Attack.create(
        setProp(props)
          :set('minDamage', 0)
          :set('maxDamage', 0)
          :set('targetGroup', 'ai')
      )
		end
	}
})