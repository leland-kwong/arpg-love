local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemSystem = require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local Vec2 = require 'modules.brinevector'

local weaponCooldown = 0.1

return {
	type = "base.action-module-frost-orb",

	blueprint = {
		extraModifiers = {
		},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-frost-orb",
		title = 'frost-orb',
		baseDropChance = 1,
		category = itemConfig.category.ACTION_MODULE,

		info = {
			cooldown = 1.1,
			actionSpeed = 0.35,
			energyCost = 8
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.frost-orb')({
			coldDamage = Vec2(1, 2),
			lifeTime = 0.5
		})
	}
}