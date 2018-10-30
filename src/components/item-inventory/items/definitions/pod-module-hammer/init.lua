local itemConfig = require 'components.item-inventory.items.config'

local itemSource = 'H_2_HAMMER'

return {
	type = 'pod-module-hammer',

	blueprint = {
		extraModifiers = {
			require 'components.item-inventory.items.modifiers.stat'({
				maxHealth = 1,
				healthRegeneration = 1
			}),
			require(require('alias').path.items..'.modifiers.upgrade-force-field')({
				experienceRequired = 0,
				size = 17,
				maxShieldHealth = 30,
				unhitDurationRequirement = 1.5,
			}),
			require(require('alias').path.items..'.modifiers.upgrade-shock-wave')({
				experienceRequired = 20,
				minDamage = 3,
				maxDamage = 5,
			})
		},

		experience = 0,
		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.aoe-slam')({
			minDamage = 5,
			maxDamage = 7
		})
	},

	properties = {
		sprite = "weapon-module-hammer",
		title = 'h-2 hammer',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		levelRequirement = 1,

		renderAnimation = 'weapon-hammer-attachment',

		baseModifiers = {
			attackTime = 0.42,
			cooldown = 0.1,
			energyCost = 2,
		},
	}
}