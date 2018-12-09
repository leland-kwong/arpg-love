local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemSystem = require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local Vec2 = require 'modules.brinevector'

local weaponCooldown = 0.1

return {
	type = "base.pod-module-frost-orb",

	blueprint = {
		extraModifiers = {
		},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-frost-orb",
		title = 'frost-orb',
		baseDropChance = 1,
		category = itemConfig.category.POD_MODULE,

		info = {
			cooldown = 1,
			attackTime = 0.25,
			energyCost = 6
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.frost-orb')({
      coldDamage = Vec2(1, 2)
		})
	}
}