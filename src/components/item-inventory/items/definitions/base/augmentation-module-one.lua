local itemConfig = require("components.item-inventory.items.config")

return {
	type = "base.augmentation-module-one",

	blueprint =  {
		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	},

	properties = {
		sprite = "augmentation-one",
		title = 'Augmentation One',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,

		baseModifiers = {
			percentDamage = 0.5
		},
	}
}