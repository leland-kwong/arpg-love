local itemConfig = require("components.item-inventory.items.config")

return {
	type = "air-shoes",

	blueprint =  {
		baseModifiers = {
			cooldown = {1.5, 1.5},
			moveSpeed = {120, 120},
			armor = {10, 10}
		},

		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')({
			speedBoost = 100,
			speedBoostDuration = 1,
			cooldown = 1.5
		})
	},

	properties = {
		sprite = "shoe_5",
		title = 'Air Shoes',
		baseDropChance = 1,
		category = itemConfig.category.SHOES,
	}
}