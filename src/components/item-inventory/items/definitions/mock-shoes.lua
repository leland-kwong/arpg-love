local itemConfig = require("components.item-inventory.items.config")

return {
	type = "mock-shoes",

	blueprint =  {
		baseModifiers = {
			cooldown = {1.5, 1.5},
			moveSpeed = {90, 90},
			armor = {50, 50}
		},

		extraModifiers = {},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')({
			speedBoost = 100,
			speedBoostDuration = 1,
		})
	},

	properties = {
		sprite = "shoe_5",
		title = 'Mock shoes',
		baseDropChance = 1,
		category = itemConfig.category.SHOES,
	}
}