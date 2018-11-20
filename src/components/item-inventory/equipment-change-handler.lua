local Component = require 'modules.component'
local Color = require 'modules.color'
local itemSystem = require 'components.item-inventory.items.item-system'
local msgBus = require 'components.msg-bus'
local filterCall = require 'utils.filter-call'
local noop = require 'utils.noop'

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
	Component.addToGroup(item.__id, 'activePlayerItems', item)
	local definition = itemSystem.getDefinition(item)
	local itemState = itemSystem.getState(item)
	itemState.equipped = true
	itemSystem:loadModules(item)

  itemState.listeners = {
		msgBus.on(msgBus.ENEMY_DESTROYED, function(msg)
			item.experience = item.experience + msg.experience
		end),
		msgBus.on(msgBus.NEW_GAME, function()
			msgBus.send(msgBus.EQUIPMENT_UNEQUIP, item)
      msgBus.off(itemState.listeners)
      return msgBus.CLEANUP
    end, 1)
  }
end)

msgBus.on(msgBus.EQUIPMENT_UNEQUIP, function(item)
	Component.removeFromGroup(item.__id, 'activePlayerItems')
	local itemState = itemSystem.getState(item)
	itemState.equipped = false
  msgBus.off(itemState.listeners)
end, 1)