local itemConfig = require("components.item-inventory.items.config")

return {
	type = "augmentation-module-frenzy",

	blueprint =  {
		extraModifiers = {},

		rarity = itemConfig.rarity.LEGENDARY,
		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	},

	properties = {
		sprite = "augmentation-one",
		title = 'Frenzy',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,

		baseModifiers = {
			percentDamage = 0.5,
			cooldownReduction = 0.5
		},

		extraModifiers = {
			require 'components.item-inventory.items.modifiers.frenzy'({
				maxStacks = 30,
				resetStackDelay = 1,
				attackTimeReduction = 0.01,
				energyCostReduction = -0.05,
				cooldownReduction = 0.005
			}),
		}
	}
}