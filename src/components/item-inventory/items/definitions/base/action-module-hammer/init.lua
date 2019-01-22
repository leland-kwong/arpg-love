local itemConfig = require 'components.item-inventory.items.config'

local itemSource = 'H_2_HAMMER'

return {
	type = 'base.action-module-hammer',

	blueprint = {
		extraModifiers = {
			require 'components.item-inventory.items.modifiers.stat'({
				maxHealth = 1,
				healthRegeneration = 1
			}),
		},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-hammer",
		title = 'h-2 hammer',
		baseDropChance = 1,
		category = itemConfig.category.ACTION_MODULE,

		levelRequirement = 1,

		-- renderAnimation = 'weapon-hammer-attachment',

		info = {
			actionSpeed = 0.42,
			cooldown = 0.1,
			energyCost = 4
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.aoe-slam')({
			minDamage = 4,
			maxDamage = 8,
			w = 40,
			h = 40
		})
	}
}