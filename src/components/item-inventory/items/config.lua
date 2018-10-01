--[[
Item gui configuration
]]--
local Color = require('modules.color')
local objectUtils = require("utils.object-utils")
local config = {}

config.rarity = {
	-- normals roll with no special modifiers
	NORMAL = 0,

	-- magicals and rares are rolled as normal items with additional modifiers
	MAGICAL = 1,
	RARE = 2,

	-- epics and legendaries have a fixed set of modifiers
	EPIC = 3,
	LEGENDARY = 4
}

config.baseDropChance = {
	[config.rarity.NORMAL] = 40,
	[config.rarity.MAGICAL] = 30,
	[config.rarity.RARE] = 18,
	[config.rarity.EPIC] = 7,
	[config.rarity.LEGENDARY] = 5
}

config.rarityColor = {
	[config.rarity.NORMAL] = Color.WHITE,
	[config.rarity.MAGICAL] = Color.RARITY_MAGICAL,
	[config.rarity.RARE] = Color.RARITY_RARE,
	[config.rarity.EPIC] = Color.RARITY_EPIC,
	[config.rarity.LEGENDARY] = Color.RARITY_LEGENDARY
}

config.rarityTitle = {
	[config.rarity.NORMAL] = nil,
	[config.rarity.MAGICAL] = 'magical',
	[config.rarity.RARE] = 'rare',
	[config.rarity.EPIC] = 'epic',
	[config.rarity.LEGENDARY] = 'legendary'
}

local consumableCategory = {
	CONSUMABLE = 'CONSUMABLE'
}
config.consumableCategory = consumableCategory

local equipmentCategory = {
	BODY_ARMOR = 'BODY_ARMOR',
	POD_MODULE = 'POD_MODULE',
	SHOES = 'SHOES',
	HELMET = 'HELMET',
	RELIC = 'RELIC',
}
config.equipmentCategory = equipmentCategory

config.category = objectUtils.assign(
	config.consumableCategory,
	config.equipmentCategory
)

config.categoryTitle = {
	[equipmentCategory.POD_MODULE] = 'pod module',
	[consumableCategory.CONSUMABLE] = 'consumable',
	[equipmentCategory.HELMET] = 'helmet',
	[equipmentCategory.BODY_ARMOR] = 'chest armor',
	[equipmentCategory.SHOES] = 'shoes',
	[equipmentCategory.RELIC] = 'relic'
}

config.equipmentCategorySilhouette = {
	[equipmentCategory.POD_MODULE] = 'weapon-module-empty',
	[consumableCategory.CONSUMABLE] = 'potion_48',
	[equipmentCategory.HELMET] = 'helmet_106',
	[equipmentCategory.BODY_ARMOR] = 'armor_121',
	[equipmentCategory.SHOES] = 'shoe_1',
	[equipmentCategory.RELIC] = 'amulet_13'
}

-- defines what gui node that equipment may be dropped into
config.equipmentGuiSlotMap = {
	{
		equipmentCategory.POD_MODULE,
		equipmentCategory.POD_MODULE
	},
	{
		equipmentCategory.POD_MODULE,
		equipmentCategory.POD_MODULE
	},
	{
		equipmentCategory.HELMET,
		equipmentCategory.BODY_ARMOR
	},
	{
		equipmentCategory.SHOES,
		equipmentCategory.RELIC
	},
	{
		consumableCategory.CONSUMABLE,
		consumableCategory.CONSUMABLE
	},
}

function config.findEquipmentSlotByCategory(category)
	assert(config.category[category] ~= nil, 'invalid category '..category)

	local slotX, slotY
	local hasMatch = false
	require'utils.iterate-grid'(config.equipmentGuiSlotMap, function(v, x, y)
		-- return the first slot that matches the category
		if hasMatch then
			return
		end

		hasMatch = v == category
		if hasMatch then
			slotX, slotY = x, y
		end
	end)
	return slotX, slotY
end

return config