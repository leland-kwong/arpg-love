local itemConfig = require(require('alias').path.itemConfig)

return {
	type = "base.potion-energy",

	blueprint = {
	},

	properties = {
		sprite = "vial-energy",
		title = "Vial of Energy",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,

		baseModifiers =  {
			cooldown = 10,
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'(),
		onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal'({
			minHeal = 50,
			maxHeal = 60,
			duration = 5,
			property = 'energy',
			maxProperty = 'maxEnergy'
		}),
	}
}