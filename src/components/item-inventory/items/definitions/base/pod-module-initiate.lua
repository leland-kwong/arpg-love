local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemSystem = require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'

local weaponCooldown = 0.1

return {
	type = "base.pod-module-initiate",

	blueprint = {
		extraModifiers = {
			require(require('alias').path.items..'.modifiers.upgrade-shock')({
				experienceRequired = 20,
				duration = 0.4,
				minDamage = 1,
				maxDamage = 2
			}),
			require(require('alias').path.items..'.modifiers.upgrade-bouncing-strike')({
				experienceRequired = 120,
				maxBounces = 1
			})
		},

		experience = 0,
		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.plasma-shot')({
			minDamage = 2,
			maxDamage = 4
		})
	},

	properties = {
		sprite = "weapon-module-initiate",
		title = 'r-1 initiate',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		baseModifiers = {
			cooldown = 0.1,
			attackTime = 0.25,
			energyCost = 1
		},
	}
}