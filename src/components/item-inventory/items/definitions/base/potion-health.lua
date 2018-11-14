local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "base.potion-health",

	blueprint = {
		extraModifiers = {},
	},

	properties = {
		sprite = "vial-health",
		title = "Vial of Health",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,

		baseModifiers =  {
			cooldown = 8,
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'({
			minHeal = 80,
			maxHeal = 100,
			duration = 6.5,
			property = 'health',
			maxProperty = 'maxHealth'
		}),
	}
}