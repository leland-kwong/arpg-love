local itemDefinition = require'components.item-inventory.items.item-definitions'
local msgBus = require'components.msg-bus'
local noop = require'utils.noop'

local equipmentSubscribers = {
	-- handle static props
	staticModifiers = function(item)
		return function(msgValue, msgType)
			if msgBus.GAME_UNLOADED == msgType then
				return msgBus.CLEANUP
			end

			local shouldCleanup = (msgBus.EQUIPMENT_UNEQUIP == msgType) and (msgValue == item)
			if shouldCleanup then
				return msgBus.CLEANUP
			end

			-- add the item's stats to the list of modifiers
			if msgBus.PLAYER_STATS_NEW_MODIFIERS == msgType then
				-- add up item properties with the new modifiers list
				for k,v in pairs(msgValue) do
					msgValue[k] = msgValue[k] + (item[k] or 0)
				end
				return msgValue
			end
			return msgValue
		end
	end
}

return function(rootStore)
	local curState, lastState = rootStore:get()
  --[[
    NOTE: we must unequip items before equipping new ones in order to make sure the newest modifiers
    are applied at the end. If the order is wrong, some some of the cleanup methods from the previous
    items may remove the newly equipped item's effects.
  ]]
	local iterateGrid = require 'utils.iterate-grid'
  iterateGrid(lastState.equipment, function(item, x, y)
		local isEquipped = item and (curState.equipment[y][x] == item)
		if isEquipped then
			-- require'utils.pprint'(item)
		end
		if item and (not isEquipped) then
			msgBus.send(msgBus.EQUIPMENT_UNEQUIP, item)
		end
  end)

	iterateGrid(curState.equipment, function(item, x, y)
    local definition = itemDefinition.getDefinition(item)
    if definition then
      local category = definition.category
      local modifier = definition.modifier
      local onMessage = definition.onMessage
      local final = definition.final
      local newlyEquipped = lastState.equipment[y][x] ~= item
      if newlyEquipped then
				definition.onEquip(item)
				msgBus.send(msgBus.ITEM_EQUIPPED, item)
				msgBus.on(msgBus.ALL, equipmentSubscribers.staticModifiers(item), 1)
				msgBus.on(msgBus.EQUIPMENT_UNEQUIP, function(_item)
					if _item == item then
						definition.final(item)
						return msgBus.CLEANUP
					end
				end)
				msgBus.on(msgBus.GAME_UNLOADED, function()
					definition.final(item)
					return msgBus.CLEANUP
				end)
      end
    end
  end)

	local BaseStatModifiers = require'components.state.base-stat-modifiers'
  local nextModifiers = BaseStatModifiers()
  msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS, nextModifiers)
end