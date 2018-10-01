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
local Enum = require 'utils.enum'

local isDebug = require'config.config'.isDebug

local types = {}
local items = {
	types = types,
	moduleTypes = Enum({
		'EQUIPMENT_ACTIVE',
		'INVENTORY_ACTIVE'
	})
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
		local loadModule = require 'modules.load-module'
		local errorFree, loadedItem = loadModule(require('alias').path.itemDefs, iType)
		if (errorFree and loadedItem) then
			return items.registerType(loadedItem)
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

function items.registerType(itemDefinition)
	local def = itemDefinition

	local registered = types[def.type] ~= nil
	if registered then
		return itemDefinition
	end

	local isDuplicateType = types[def.type] ~= nil
	assert(not isDuplicateType, "duplicate item type ".."\""..def.type.."\"")

	types[def.type] = def.properties

	if isDebug then
		assert(itemDefinition ~= nil, "item type missing")
		local file = 'components/item-inventory/items/definitions/'..def.type
		assert(
			require(file) ~= nil,
			'Invalid type `'..tostring(def.type)..'`. Type should match the name of the file since its needed for dynamic requires'
		)
	end

	return types[def.type]
end

local factoriesByType = {}
-- Factory function that creates a new instance based on the module's instance props.
function items.create(module)
	local createFn = factoriesByType[module.type]
	if not createFn then
		local ser = require 'utils.ser'
		createFn = loadstring(ser(module.instanceProps))
		factoriesByType[module.type] = createFn
	end

	local newItem = createFn()

	-- set modifiers to value based on range parameters
	for k,v in pairs(newItem.baseModifiers) do
		newItem.baseModifiers[k] = math.random(v[1], v[2])
	end

	newItem.__type = module.type
	newItem.__id = uid()

	-- add default props if needed
	newItem.experience = newItem.experience or 0
	newItem.stackSize = newItem.stackSize == nil and 1 or newItem.stackSize
	newItem.maxStackSize = newItem.maxStackSize == nil and 1 or newItem.maxStackSize
	return newItem
end

local modulesById = {}

function items.registerModule(module)
	local id = module.type .. '_' .. module.name
	assert(type(module.name) == 'string', 'modules must have a unique name')
	assert(items.moduleTypes[module.type], 'invalid module type '..module.type)
	assert(not modulesById[id], 'duplicate module with id '..id)
	modulesById[id] = module
	return id
end

local directoriesByModuleType = {
	[items.moduleTypes.EQUIPMENT_ACTIVE] = 'equipment-actives',
	[items.moduleTypes.INVENTORY_ACTIVE] = 'inventory-actives',
}

local function loadModuleById(id)
	local start, _end = string.find(id, '[^_]*')
	local fileName = string.sub(id, start, _end)
	local type = string.sub(id, _end + 2)
	local directory = 'components.item-inventory.items.' .. directoriesByModuleType[type]
	local fullPath = directory.. '.' ..fileName
	return require(fullPath)
end

function items.getModuleById(id)
	return modulesById[id]
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

function items.resetState(item)
	statesById:delete(item.__id)
end

return items