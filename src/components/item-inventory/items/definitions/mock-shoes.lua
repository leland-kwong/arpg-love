local itemConfig = require("components.item-inventory.items.config")

return {
	type = "mock-shoes",

	instanceProps =  {
		props = {
			speedBoost = 300,
			speedBoostDuration = 1
		},

		baseModifiers = {
			armor = {20, 30},
			moveSpeed = {100, 100},
			fireResist = {20, 25},
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click',
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')
	},

	properties = {
		sprite = "shoe_5",
		title = 'Mock shoes',
		baseDropChance = 1,
		category = itemConfig.category.SHOES,
	}
}