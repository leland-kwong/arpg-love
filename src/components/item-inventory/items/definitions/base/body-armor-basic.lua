local itemConfig = require("components.item-inventory.items.config")

return {
	type = "base.body-armor-basic",

	blueprint =  {
		extraModifiers = {},
	},

	properties = {
		sprite = "body-armor-basic",
		title = 'Light plate',
		baseDropChance = 1,
		category = itemConfig.category.BODY_ARMOR,

		baseModifiers = {
			armor = 400
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	}
}