local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "potion-health",

	blueprint = {
		props = {
			heal = {80, 100},
			duration = 2,
		},

		baseModifiers =  {
			armor = {50, 100}
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'(),
	},

	properties = {
		sprite = "potion_48",
		title = "Potion of Healing",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,
	}
}