local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "base.potion-health",

	blueprint = {
		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'({
			minHeal = 80,
			maxHeal = 100,
			duration = 6.5,
			property = 'health',
			maxProperty = 'maxHealth'
		}),
	},

	properties = {
		sprite = "potion_48",
		title = "Potion of Healing",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,

		baseModifiers =  {
			cooldown = 8,
		},
	}
}