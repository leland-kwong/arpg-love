local itemConfig = require("components.item-inventory.items.config")

return {
	type = "legendary.defender-of-aureus",

	blueprint =  {
		extraModifiers = {},

		rarity = itemConfig.rarity.LEGENDARY,
	},

	properties = {
		sprite = "augmentation-defender",
		title = 'Defender of Aureus',
		baseDropChance = 1,
		category = itemConfig.category.AUGMENTATION,

		baseModifiers = {
			percentDamage = 0.3
		},

		extraModifiers = {
			require 'components.item-inventory.items.modifiers.upgrade-force-field'({
				experienceRequired = 0,
				size = 30,
				bonusAbsorption = 10,
				baseAbsorption = 15
			}),
		},

		onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click'()
	}
}