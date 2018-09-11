--[[
Item gui configuration
]]--
local Color = require('modules.color')
local objectUtils = require("utils.object-utils")
local config = {}

config.rarity = {
	NORMAL = 0,
	MAGICAL = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4
}

local COLOR_MAGICAL = {Color.rgba255(107, 171, 255)} -- blueish-purple
local COLOR_RARE = {1, 1, 0} -- yellow
local COLOR_EPIC = {Color.rgba255(228, 96, 255)} -- magenta
local COLOR_LEGENDARY = {Color.rgba255(255, 155, 33)} -- gold

config.rarityColor = {
	[config.rarity.NORMAL] = Color.WHITE,
	[config.rarity.MAGICAL] = COLOR_MAGICAL,
	[config.rarity.RARE] = COLOR_RARE,
	[config.rarity.EPIC] = COLOR_EPIC,
	[config.rarity.LEGENDARY] = COLOR_LEGENDARY
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