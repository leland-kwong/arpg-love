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
			cooldown = 0.7,
		},

		baseModifiers = {
			moveSpeed = 10,
			armor = 50
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')({
			distance = 4,
			duration = 6/60,
		})
	}
}