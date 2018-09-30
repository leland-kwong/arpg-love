local Component = require 'modules.component'
local Color = require 'modules.color'
local itemDefinition = require 'components.item-inventory.items.item-definitions'
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

local function triggerUpgradeMessage(item, level)
  msgBus.send(
    msgBus.ITEM_UPGRADE_UNLOCKED, {
      item = item,
      level = level
    }
  )
end

local function getHighestUpgradeUnlocked(upgrades, item)
	local highestUpgradeUnlocked = 0
	local upgradeCount = upgrades and #upgrades or 0
	for level=1, upgradeCount do
		local up = upgrades[level]
		if item.experience >= up.experienceRequired then
			highestUpgradeUnlocked = level
			triggerUpgradeMessage(item, level)
		end
	end
	return highestUpgradeUnlocked
end

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
		local definition = itemDefinition.getDefinition(item)
		itemDefinition.resetState(item)
		definition.onEquip(item)
		local category = definition.category
		local modifier = definition.modifier
		local onMessage = definition.onMessage
		local final = definition.final
		local upgrades = definition.upgrades
		local lastUpgradeUnlocked = getHighestUpgradeUnlocked(upgrades, item)
		local itemState = itemDefinition.getState(item)
		msgBus.send(msgBus.ITEM_EQUIPPED, item)
		itemState.listeners = {
			msgBus.on(msgBus.ENTITY_DESTROYED, function(v)
				item.experience = item.experience + v.experience
				local nextUpgradeLevel = getHighestUpgradeUnlocked(upgrades, item)
				local newUpgradeUnlocked = nextUpgradeLevel > lastUpgradeUnlocked
				lastUpgradeUnlocked = nextUpgradeLevel
				if newUpgradeUnlocked then
					local itemTitle = definition.title
					msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
						title = itemTitle..' upgraded',
						icon = definition.sprite,
						description = {
							Color.CYAN, upgrades[nextUpgradeLevel].title,
							Color.WHITE, ' is unlocked'
						}
					})
					triggerUpgradeMessage(item, nextUpgradeLevel)
				end
			end),
			msgBus.on(msgBus.ALL, equipmentSubscribers.staticModifiers(item), 1),
			msgBus.on(msgBus.EQUIPMENT_UNEQUIP, function(_item)
				if _item == item then
					definition.final(item)
					msgBus.off(itemState.listeners)
					return msgBus.CLEANUP
				end
			end),
			msgBus.on(msgBus.NEW_GAME, function()
				definition.final(item)
				msgBus.off(itemState.listeners)
				return msgBus.CLEANUP
			end)
		}
	end, function(item)
		return not not item
	end))

	local BaseStatModifiers = require'components.state.base-stat-modifiers'
	local nextModifiers = BaseStatModifiers()
  msgBus.send(msgBus.PLAYER_STATS_NEW_MODIFIERS, nextModifiers)
end)

msgBus.on(msgBus.ITEM_CHECK_UPGRADE_AVAILABILITY, function(v)
  local item, level = v.item, v.level
  local upgrades = itemDefinition.getDefinition(item).upgrades
  return item.experience >= upgrades[level].experienceRequired
end)