local itemConfig = require("components.item-inventory.items.config")

return {
	type = "augmentation-module-one",

	blueprint =  {
		baseModifiers = {
			percentDamage = {1, 1}
		},

		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	},

	properties = {
		sprite = "amulet_10",
		title = 'Augmentation One',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,
	}
}