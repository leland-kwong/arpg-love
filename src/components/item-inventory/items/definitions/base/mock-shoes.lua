local itemConfig = require("components.item-inventory.items.config")

return {
	type = "base.mock-shoes",

	blueprint =  {
		extraModifiers = {},
	},

	properties = {
		sprite = "shoe_5",
		title = 'Mock shoes',
		baseDropChance = 1,
		category = itemConfig.category.SHOES,

		info = {
			cooldown = 1.6,
		},

		baseModifiers = {
			moveSpeed = 40,
			armor = 50
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')({
			distance = 8,
			duration = 15/60,
		})
	}
}