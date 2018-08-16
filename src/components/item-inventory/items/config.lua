--[[
Item gui configuration
]]--
local objectUtils = require("utils.object-utils")
local config = {}

config.rarity = {
	NORMAL = 0,
	MAGICAL = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4
}

config.rarityColor = {
	[config.rarity.NORMAL] = '#fff',
	[config.rarity.MAGICAL] = '#6babff',
	[config.rarity.RARE] = 'yellow',
	[config.rarity.EPIC] = 'magenta',
	[config.rarity.LEGENDARY] = 'orange'
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
	RING = 4,
	AMULET = 5,
	SHOES = 6,
	PANTS = 7,
	GLOVES = 8,
	ION_GENERATOR = 9
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

-- defines what gui node that equipment may be dropped into
config.equipmentGuiRenderNodeMap = {
	-- [equipmentCategory.BODY_ARMOR] = guiNodes.equipment.bodyArmorIcon,
	-- [equipmentCategory.SHOES] = guiNodes.equipment.shoesIcon,
	-- [equipmentCategory.WEAPON_1] = guiNodes.equipment.weapon1Icon,
	-- [equipmentCategory.ION_GENERATOR] = guiNodes.equipment.ionGeneratorIcon
}

config.equipmentGuiHitBoxNodeMap = {
	-- [equipmentCategory.BODY_ARMOR] = guiNodes.equipment.bodyArmorRoot,
	-- [equipmentCategory.SHOES] = guiNodes.equipment.shoesRoot,
	-- [equipmentCategory.WEAPON_1] = guiNodes.equipment.weapon1Root,
	-- [equipmentCategory.ION_GENERATOR] = guiNodes.equipment.ionGeneratorRoot,
}

return config