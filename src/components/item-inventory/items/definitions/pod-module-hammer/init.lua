local itemConfig = require 'components.item-inventory.items.config'

local itemSource = 'H_2_HAMMER'

return {
	type = 'pod-module-hammer',

	blueprint = {
		baseModifiers = {
			attackTime = {0.3, 0.3},
			maxHealth = {100, 100},
			weaponDamage = {2, 2},
			energyCost = {2, 2},
		},

		extraModifiers = {
			require(require('alias').path.items..'.modifiers.upgrade-force-field')({
				experienceRequired = 0,
				size = 17,
				maxShieldHealth = 30,
				unhitDurationRequirement = 1.5,
			}),
			require(require('alias').path.items..'.modifiers.upgrade-shock-wave')({
				experienceRequired = 0,
			}),
			require(require('alias').path.items..'.modifiers.regeneration')(function()
				return {
					rate = 10,
					property = 'health',
					maxProperty = 'maxHealth'
				}
			end),
		},

		experience = 0,
		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.aoe-slam')()
	},

	properties = {
		sprite = "weapon-module-hammer",
		title = 'h-2 hammer',
		rarity = itemConfig.rarity.NORMAL,
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		levelRequirement = 1,
		attackTime = attackTime,

		renderAnimation = 'weapon-hammer-attachment'
	}
}