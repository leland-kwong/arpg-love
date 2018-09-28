--[[
TODO: Load items asynchronously as needed.
As an item gets discovered, drops from an enemy, or shows up in the npc shop, we'll
load the item definition from disk.
]]

--[[
Item factories

First function returns a table of the item data
]]--

local tableUtils = require("utils.object-utils")

local uid = require("utils.uid")
local itemConfig = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")

local isDebug = require'config.config'.isDebug

local types = {}
local items = {
	types = types,
}

function items.isItem(value)
	return type(value) == 'table'
		-- check if type exists
		and types[value.__type] ~= nil
end

local loadedTypes = {}
local function requireIfNecessary(item)
	local iType = item.__type
	if (not loadedTypes[iType]) then
		local errorFree, loadedItem = pcall(function()
			local requirePath = 'components.item-inventory.items.definitions.'..iType
			local module = require(requirePath)
			return module
		end)
		loadedTypes[iType] = true
		if (errorFree and loadedItem) then
			return items.types[iType]
		end
	end
	return nil
end

function items.getDefinition(item)
	if not item then
		return nil
	end
	return items.types[item.__type] or requireIfNecessary(item)
end

local noop = function() end
local defaultProperties = {
	-- static sprite to render when equipped
	renderAnimation = nil,

	onEquip = noop,

	-- tooltip content to render
	tooltip = noop,

	-- tooltip info for upgrade path
	tooltipItemUpgrade = noop,

	-- item picked up from ground, given as a reward, etc...
	onInventoryEnter = noop,

	-- item picked up from inventory cell
	onInventoryPickup = noop,

	-- item dropped into inventory cell
	onInventoryDrop = noop,

	-- item is right-clicked in inventory
	onActivate = noop,

	-- item is equipped and item is in active skill slot
	onActivateWhenEquipped = nil,

	render = noop,

	modifier = function(self, msgType, msgValue)
		return msgValue
	end,

	-- item is unequipped, sold, or destroyed
	final = noop,

	energyCost = function()
		return 0
	end
}

-- setup methods so we can call them with the item
for method,_ in pairs(defaultProperties) do
	items[method] = function(item, mainStore)
		local definition = items.getDefinition(item)
		if definition == nil then
			return nil
		end
		return definition[method](item, mainStore)
	end
end

local itemPropertiesPropTypes = {
	sprite = {
		required = true,
		type = "string"
	},
	title = {
		required = true,
		type = "string"
	},
	rarity = {
		required = true,
		type = function(rarity)
			local found = false
			for _,v in pairs(itemConfig.rarity) do
				if rarity == v then
					found = true
				end
			end
			if not found then
				error("invalid `rarity` `"..rarity.."` received")
			end
		end
	},
	category = {
		required = true,
		type = function(category)
			local found = false
			for _,v in pairs(itemConfig.category) do
				if category == v then
					found = true
				end
			end
			if not found then
				error("invalid `category` `"..category.."` received")
			end
		end
	},
	upgrades = {
		type = function(upgrades)
			local forEach = require 'utils.functional'.forEach
			forEach(upgrades, function(up)
				assert(type(up.title) == 'string')
				assert(type(up.description) == 'string')
				assert(
					type(up.props) == 'table' or (up.props == nil)
				)
				assert(type(up.experienceRequired) == 'number')
				assert(
					type(up.sprite) == 'string' or (up.sprite == nil)
				)
			end)
		end
	}
}

local function checkPropTypes(valueToCheck, scope, types)
	local msgScope = "["..scope.."] "
	for k,v in pairs(types) do

		local valueAtKey = valueToCheck[k]
		if v.required then
			assert(valueAtKey ~= nil, msgScope.."prop `"..k.."` is required")
		end
		-- check type
		if valueAtKey ~= nil then
			if type(v.type) == "function" then
				v.type(valueAtKey)
			else
				local msg = msgScope.."invalid propType `"..k.."`. Received `"..valueAtKey.."`, expected type "..v.type
				assert(type(valueAtKey) == v.type, msg)
			end
		end
	end
end

function items.registerType(itemDefinition)
	local def = itemDefinition

	local registered = types[def.type] ~= nil
	if registered then
		return itemDefinition
	end

	local isDuplicateType = types[def.type] ~= nil
	assert(not isDuplicateType, "duplicate item type ".."\""..def.type.."\"")

	types[def.type] = tableUtils.assign({
		registered = true,
		-- factory function thats calls the item's create method
		-- and returns instance-specific properties.
		-- Instance-specific properties are static.
		create = function()
			local newItem = def.create()
			-- TODO: nest these under `meta` property
			newItem.__type = def.type
			newItem.__id = uid()

			-- add default props if needed
			newItem.experience = newItem.experience or 0
			newItem.stackSize = newItem.stackSize == nil and 1 or newItem.stackSize
			newItem.maxStackSize = newItem.maxStackSize == nil and 1 or newItem.maxStackSize
			return newItem
		end
	}, defaultProperties, def.properties)

	if isDebug then
		assert(itemDefinition ~= nil, "item type missing")
		local file = 'components/item-inventory/items/definitions/'..def.type
		assert(
			require(file) ~= nil,
			'Invalid type `'..tostring(def.type)..'`. Type should match the name of the file since its needed for dynamic requires'
		)
		checkPropTypes(def.properties, def.type, itemPropertiesPropTypes)
	end

	return types[def.type]
end

local Lru = require 'utils.lru'
local setProp = require 'utils.set-prop'
local statesById = Lru.new(100)

function items.getState(item)
	local id = item.__id
	local state = statesById:get(id)
	if (not state) then
		state = setProp({})
		statesById:set(id, state)
	end
	return state
end

return items