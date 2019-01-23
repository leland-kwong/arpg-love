local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemSystem = require("components.item-inventory.items.item-system")
local functional = require("utils.functional")
local AnimationFactory = require 'components.animation-factory'
local Vec2 = require 'modules.brinevector'

return {
	type = "base.action-module-chain-lightning",

	blueprint = {
		extraModifiers = {
		},

		experience = 0,
	},

	properties = {
		sprite = "weapon-module-lightning-rod",
		title = 'chain-lightning',
		baseDropChance = 1,
		category = itemConfig.category.ACTION_MODULE,

		info = {
			cooldown = 0,
			actionSpeed = 0.3,
			energyCost = 3
		},

		onActivate = require(require('alias').path.items..'.inventory-actives.equip-on-click')(),
		onActivateWhenEquipped = require(require('alias').path.items..'.equipment-actives.chain-lightning')({
			lightningDamage = Vec2(1, 5),
			maxBounces = 2
		})
	}
}