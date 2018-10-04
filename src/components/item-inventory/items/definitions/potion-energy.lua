local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "potion-energy",

	blueprint = {
		baseModifiers =  {
			armor = {50, 100}
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'({
			minHeal = 50,
			maxHeal = 60,
			duration = 2,
			property = 'energy',
			maxProperty = 'maxEnergy'
		}),
	},

	properties = {
		sprite = "potion_40",
		title = "Potion of Energy",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,
	}
}