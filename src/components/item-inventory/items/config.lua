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
	CONSUMABLE = 1
}
config.consumableCategory = consumableCategory

local equipmentCategory = {
	BODY_ARMOR = 2,
	WEAPON_1 = 3,
	AMULET = 4,
	SHOES = 5,
	PANTS = 6,
	GLOVES = 7,
	ION_GENERATOR = 8,
	HELMET = 9,
	RING = 10,
}
config.equipmentCategory = equipmentCategory

config.category = objectUtils.assign(
	config.consumableCategory,
	config.equipmentCategory
)

config.categoryTitle = {
	[consumableCategory.CONSUMABLE] = 'consumable',
	[equipmentCategory.BODY_ARMOR] = 'chest armor',
	[equipmentCategory.WEAPON_1] = 'weapon',
	[equipmentCategory.RING] = 'ring',
	[equipmentCategory.AMULET] = 'amulet',
	[equipmentCategory.SHOES] = 'shoes',
	[equipmentCategory.PANTS] = 'pants',
	[equipmentCategory.GLOVES] = 'gloves',
	[equipmentCategory.ION_GENERATOR] = 'ion generator',
}

config.equipmentCategorySilhouette = {
	[equipmentCategory.HELMET] = 'helmet_106',
	[equipmentCategory.ION_GENERATOR] = 'book_25',
	[equipmentCategory.RING] = 'ring_1',
	[equipmentCategory.AMULET] = 'amulet_16',
	[equipmentCategory.BODY_ARMOR] = 'armor_121',
	[equipmentCategory.WEAPON_1] = 'sword_17',
	[equipmentCategory.SHOES] = 'shoe_1'
}

-- defines what gui node that equipment may be dropped into
config.equipmentGuiSlotMap = {
	{
		equipmentCategory.HELMET,
		equipmentCategory.BODY_ARMOR
	},
	{
		equipmentCategory.ION_GENERATOR,
		equipmentCategory.RING
	},
	{
		equipmentCategory.WEAPON_1,
		equipmentCategory.WEAPON_1
	},
	{
		equipmentCategory.SHOES,
		equipmentCategory.AMULET
	}
}

function config.findEquipmentSlotByCategory(category)
	assert(type(category) == 'number', 'invalid category '..category..' should be of type number')

	local slotX, slotY
	require'utils.iterate-grid'(config.equipmentGuiSlotMap, function(v, x, y)
		if v == category then
			slotX, slotY = x, y
		end
	end)
	return slotX, slotY
end

return config