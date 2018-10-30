local Component = require 'modules.component'
local Color = require 'modules.color'
local itemSystem = require 'components.item-inventory.items.item-system'
local msgBus = require 'components.msg-bus'
local filterCall = require 'utils.filter-call'
local noop = require 'utils.noop'

local equipmentSubscribers = {
	-- handle static props
	staticModifiers = function(item)
		return function(msgValue, msgType)
			if msgBus.NEW_GAME == msgType then
				return msgBus.CLEANUP
			end

			local shouldCleanup = (msgBus.EQUIPMENT_UNEQUIP == msgType) and (msgValue == item)
			if shouldCleanup then
				return msgBus.CLEANUP
			end

			-- add the item's stats to the list of modifiers
			if msgBus.PLAYER_STATS_NEW_MODIFIERS == msgType then
				print(
					Inspect(
						itemSystem.getDefinition(item)
					)
				)
				-- add up item properties with the new modifiers list
				for k,v in pairs(msgValue) do
					msgValue[k] = msgValue[k] + (itemSystem.getDefinition(item).baseModifiers[k] or 0)
				end
				return msgValue
			end
			return msgValue
		end
	end
}

msgBus.on(msgBus.EQUIPMENT_CHANGE, function()
	local rootStore = msgBus.send(msgBus.GAME_STATE_GET)
	local curState, lastState = rootStore:get()
  --[[
    NOTE: we must unequip items before equipping new ones in order to make sure the newest modifiers
    are applied at the end. If the order is wrong, some some of the cleanup methods from the previous
    items may remove the newly equipped item's effects.
  ]]
	local iterateGrid = require 'utils.iterate-grid'
  iterateGrid(lastState.equipment, filterCall(function(item, x, y)
		msgBus.send(msgBus.EQUIPMENT_UNEQUIP, item)
	end, function(item)
		return not not item
	end))

	iterateGrid(curState.equipment, filterCall(function(item, x, y)
		-- refresh equipment by unequipping first
		msgBus.send(msgBus.EQUIPMENT_UNEQUIP, item)
		itemSystem.resetState(item)
		msgBus.send(msgBus.ITEM_EQUIPPED, item)
	end, function(item)
		return not not item
	end))

  msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS)
end)

msgBus.on(msgBus.ITEM_EQUIPPED, function(item)
	local definition = itemSystem.getDefinition(item)
	local itemState = itemSystem.getState(item)
	itemState.equipped = true
	itemSystem:loadModules(item)

  itemState.listeners = {
    msgBus.on(msgBus.ALL, equipmentSubscribers.staticModifiers(item), 1),
		msgBus.on(msgBus.NEW_GAME, function()
			msgBus.send(msgBus.EQUIPMENT_UNEQUIP, item)
      msgBus.off(itemState.listeners)
      return msgBus.CLEANUP
    end, 1)
  }
end)

msgBus.on(msgBus.EQUIPMENT_UNEQUIP, function(item)
	local itemState = itemSystem.getState(item)
	itemState.equipped = false
  msgBus.off(itemState.listeners)
end, 1)

msgBus.on(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, function(v)
  local item, level = v.item, v.level
  local upgrades = itemSystem.getDefinition(item).upgrades
  return item.experience >= upgrades[level].experienceRequired
end)