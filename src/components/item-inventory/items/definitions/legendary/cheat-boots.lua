local itemConfig = require("components.item-inventory.items.config")

return {
	type = "legendary.cheat-boots",

	blueprint =  {
		extraModifiers = {},
	},

	properties = {
		sprite = "shoe_5",
		title = 'Cheat boots',
		baseDropChance = 1,
		category = itemConfig.category.SHOES,

		info = {
			cooldown = 0.1,
		},

		baseModifiers = {
			moveSpeed = 200,
			armor = 50
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.movespeed-boost')({
			distance = 10,
			duration = 6/60,
		})
	}
}