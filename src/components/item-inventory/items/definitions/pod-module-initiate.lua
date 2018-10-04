local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemSystem = require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'

local weaponCooldown = 0.1

return {
	type = "pod-module-initiate",

	blueprint = {
		props = {
			weaponCooldown = weaponCooldown,
			attackTime = weaponCooldown - 0.01
		},

		baseModifiers = {
			weaponDamage = {1, 1},
			energyCost = {1, 1}
		},

		extraModifiers = {
			require(require('alias').path.items..'.modifiers.upgrade-shock')({
				experienceRequired = 120
			})
		},

		experience = 120,
		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.plasma-shot')()
	},

	properties = {
		sprite = "weapon-module-initiate",
		title = 'r-1 initiate',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		tooltipItemUpgrade = function(self)
			return upgrades
		end,
	}
}