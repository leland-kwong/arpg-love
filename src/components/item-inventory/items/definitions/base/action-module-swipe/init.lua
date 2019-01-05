local itemConfig = require 'components.item-inventory.items.config'

local itemSource = 'H_2_HAMMER'

return {
	type = 'base.action-module-swipe',

	blueprint = {
		extraModifiers = {},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-swipe",
		title = 'swipe',
		baseDropChance = 1,
		category = itemConfig.category.ACTION_MODULE,

		levelRequirement = 1,

		info = {
			actionSpeed = 0.2,
			cooldown = 0.1,
			energyCost = 1
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.swipe')({
			minDamage = 3,
			maxDamage = 4,
		})
	}
}