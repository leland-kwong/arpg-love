local itemConfig = require("components.item-inventory.items.config")

return {
	type = "augmentation-module-one",

	blueprint =  {
		baseModifiers = {
			percentDamage = {0.5, 0.5}
		},

		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	},

	properties = {
		sprite = "augmentation-one",
		title = 'Augmentation One',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,
	}
}