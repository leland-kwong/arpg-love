local itemConfig = require("components.item-inventory.items.config")
local itemDefs = require("components.item-inventory.items.item-definitions")

return itemDefs.registerType({
	type = "potion-health",

	create = function()
		return {
			baseModifiers =  {
				heal = {80, 100},
				duration = 2,
				armor = math.random(50, 100)
			},

			rarity = itemConfig.rarity.RARE,

			onActivate = require 'components.item-inventory.items.inventory-actives.equip-on-click',
			onActivateWhenEquipped = require 'components.item-inventory.items.equipment-actives.heal',
		}
	end,

	properties = {
		sprite = "potion_48",
		title = "Potion of Healing",
		baseDropChance = 1,
		category = itemConfig.category.CONSUMABLE,
	}
})