local itemConfig = require("components.item-inventory.items.config")

return {
	type = "base.augmentation-module-one",

	blueprint =  {
		extraModifiers = {},

	},

	properties = {
		sprite = "augmentation-one",
		title = 'Augmentation One',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,

		baseModifiers = {
			attackPower = 30
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	}
}