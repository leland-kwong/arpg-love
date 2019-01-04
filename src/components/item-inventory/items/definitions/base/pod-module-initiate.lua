local itemConfig = require("components.item-inventory.items.config")

return {
	type = "base.pod-module-initiate",

	blueprint = {
		extraModifiers = {},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-initiate",
		title = 'r-1 initiate',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		info = {
			cooldown = 0.1,
			attackTime = 0.25,
			energyCost = 2
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.plasma-shot')({
			minDamage = 2,
			maxDamage = 4
		})
	}
}