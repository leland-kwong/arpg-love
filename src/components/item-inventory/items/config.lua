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

-- weighted chance, sums up all values and determines the chance based on the ratio of the total.
config.baseDropChance = {
	[config.rarity.NORMAL] = 41,
	[config.rarity.MAGICAL] = 30,
	[config.rarity.RARE] = 19,

	[config.rarity.EPIC] = 0, -- we have no epics right now, so this is disabled

	[config.rarity.LEGENDARY] = 10
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
	ACTION_MODULE = 'ACTION_MODULE',
	SHOES = 'SHOES',
	HELMET = 'HELMET',
	AUGMENTATION = 'AUGMENTATION',
}
config.equipmentCategory = equipmentCategory

config.category = objectUtils.assign(
	config.consumableCategory,
	config.equipmentCategory
)

config.categoryTitle = {
	[equipmentCategory.ACTION_MODULE] = 'action module',
	[consumableCategory.CONSUMABLE] = 'consumable',
	[equipmentCategory.HELMET] = 'helmet',
	[equipmentCategory.BODY_ARMOR] = 'chest armor',
	[equipmentCategory.SHOES] = 'shoes',
	[equipmentCategory.AUGMENTATION] = 'augmentation'
}

config.equipmentCategorySilhouette = {
	[equipmentCategory.ACTION_MODULE] = 'weapon-module-empty',
	[consumableCategory.CONSUMABLE] = 'vial-health',
	[equipmentCategory.HELMET] = 'helmet_106',
	[equipmentCategory.BODY_ARMOR] = 'body-armor-basic',
	[equipmentCategory.SHOES] = 'shoe_1',
	[equipmentCategory.AUGMENTATION] = 'augmentation-one'
}

-- defines what gui node that equipment may be dropped into
config.equipmentGuiSlotMap = {
	{
		equipmentCategory.ACTION_MODULE,
		equipmentCategory.ACTION_MODULE
	},
	{
		equipmentCategory.ACTION_MODULE,
		equipmentCategory.ACTION_MODULE
	},
	{
		equipmentCategory.AUGMENTATION,
		equipmentCategory.AUGMENTATION
	},
	{
		equipmentCategory.SHOES,
		equipmentCategory.BODY_ARMOR,
	},
	{
		consumableCategory.CONSUMABLE,
		consumableCategory.CONSUMABLE
	},
}

function config.findEquipmentSlotsByCategory(category)
	assert(config.category[category] ~= nil, 'invalid category '..category)

	local validSlots = {}
	require'utils.iterate-grid'(config.equipmentGuiSlotMap, function(v, x, y)
		local hasMatch = v == category
		if (hasMatch) then
			table.insert(validSlots, {x = x, y = y})
		end
	end)
	return validSlots
end

return config