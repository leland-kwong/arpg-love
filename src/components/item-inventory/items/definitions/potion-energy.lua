local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "potion-energy",

	blueprint = {
		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'({
			minHeal = 50,
			maxHeal = 60,
			duration = 5,
			property = 'energy',
			maxProperty = 'maxEnergy'
		}),
	},

	properties = {
		sprite = "potion_40",
		title = "Potion of Energy",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,

		baseModifiers =  {
			cooldown = 10,
		},
	}
}