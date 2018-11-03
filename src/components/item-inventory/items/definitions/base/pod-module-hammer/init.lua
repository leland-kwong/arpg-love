local itemConfig = require 'components.item-inventory.items.config'

local itemSource = 'H_2_HAMMER'

return {
	type = 'base.pod-module-hammer',

	blueprint = {
		extraModifiers = {
			require 'components.item-inventory.items.modifiers.stat'({
				maxHealth = 1,
				healthRegeneration = 1
			}),
			require(require('alias').path.items..'.modifiers.upgrade-critical-hit')({
				experienceRequired = 40,
				chance = 0.25,
				minMultiplier = 0.2,
				maxMultiplier = 0.4
			}),
		},

		experience = 0,
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
			energyCost = 3
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.aoe-slam')({
			minDamage = 5,
			maxDamage = 7,
			w = 40,
			h = 40
		})
	}
}