local config = require('config.config')
local itemSystem =require("components.item-inventory.items.item-system")
local itemConfig = require("components.item-inventory.items.config")
local sc = require("components.state.constants")
local cloneGrid = require('utils.clone-grid')
local msgBus = require 'components.msg-bus'

local EMPTY_SLOT = sc.inventory.EMPTY_SLOT

return function(rootStore)

	function rootStore.isEmptyInventorySlot(itemFromSlot)
		return itemFromSlot == EMPTY_SLOT
	end

	--[[
	Adds an item to the grid position {x,y}. If no position is provided, then it does the following:
	1. If same type, add to stack until it can't add anymore
	2. Otherwise add to the nearest empty slot
	]]

	function rootStore:addItemToInventory(item, position)
		if not item then
			return
		end
		if config.isDebug then
			local valid = itemSystem.isItem(item)
			assert(valid, "item type does not exist")
		end

		local stackable = item.maxStackSize > 1
		local emptyPosition = nil
		local added = false
		local remainingStackSize = item.stackSize
		local function add(state)
			local newItems = cloneGrid(state.inventory, function(curItem, x, y)
				if added then
					return curItem
				end

				local isEmptySlot = curItem == EMPTY_SLOT
				local isSameType = not isEmptySlot and (item.__type == curItem.__type)
				local isFullStack = isSameType and (curItem.stackSize == curItem.maxStackSize)

				-- if a position is provided, then lets add it to that position
				if position then
					local correctPosition = position[1] == x and position[2] == y
					if not correctPosition then
						return curItem
					end
				end

				-- store the empty position so we can reference it later
				if isEmptySlot and not emptyPosition then
					emptyPosition = {x = x, y = y}
				end
				if stackable then
					-- add to stack if its the same type
					if isSameType and not isFullStack then
						local newStackSize = curItem.stackSize + 1
						remainingStackSize = remainingStackSize - 1
						added = true
						return require'utils.object-utils'.immutableApply(curItem, {
							stackSize = newStackSize
						})
					elseif isEmptySlot then
						remainingStackSize = 0
						added = true
						return item
					else
						return curItem
					end
				elseif isEmptySlot then
					added = true
					remainingStackSize = 0
					return item
				else
					return curItem
				end
			end, false)

			local canBeAddedToSlot = emptyPosition and (not position) and stackable and (not added)
			if canBeAddedToSlot then
				-- add to empty slot
				remainingStackSize = 0
				newItems[emptyPosition.y][emptyPosition.x] = item
				added = true
			end

			return newItems
		end

		self:set('inventory', add)

		local isFull = not added
		-- TODO: handle inventory full
		if isFull then
			-- when a position is full
			if position then
				local x,y = unpack(position)
				print("inventory at position {"..x..", "..y.."} is full")
				-- when entire inventory is full
			else
				print("inventory is full")
			end
		end

		-- recursively add until we can't add anymore
		if not isFull and remainingStackSize > 0 then
			local nextItem = require'utils.object-utils'.immutableApply(item, {
				stackSize = remainingStackSize
			})
			return self:addItemToInventory(nextItem, position)
		end

		-- if there are remaining items we'll return whats left
		return (remainingStackSize > 0) and item or nil
	end

	function rootStore:removeItem(itemToRemove, count)
		local itemId = itemToRemove.__id
		-- default to remove 1 item
		count = count == nil and 1 or count
		self:set('inventory', function(state)
			local removed = false
			local newState = cloneGrid(state.inventory, function(curItem)
				if removed then
					return curItem
				end
				local isItemToRemove = itemId == (curItem and curItem.__id)
				if isItemToRemove then
					removed = true
					-- remove from stack
					local newStackSize = curItem.stackSize - count
					local hasRemaining = newStackSize > 0
					if hasRemaining then
						return require'utils.object-utils'.immutableApply(curItem, {
							stackSize = newStackSize
						})
					end
					return EMPTY_SLOT
				end
				return curItem
			end)
			return newState
		end)
		return self
	end

	function rootStore:getItemFromPosition(x, y)
		return self:get().inventory[y][x]
	end

	function rootStore:findItemById(item)
		local id = item.__id
		local foundItem = nil
		local posX = nil
		local posY = nil
		require'utils.iterate-grid'(self:get().inventory, function(v, x, y)
			if v and (v.__id == id) then
				foundItem = v
				posX = x
				posY = y
			end
		end)
		if not foundItem then
			return false
		end
		return foundItem, posX, posY
	end

	function rootStore:pickupItem(x, y)
		local item = self:getItemFromPosition(x, y)
		if item == EMPTY_SLOT then
			return nil
		end
		-- Currently only supports picking up full stack
		local count = item.stackSize
		self:removeItem(item, count)
		return item
	end

	-- drops the item into the slot and handles swapping based on the item type
	function rootStore:dropItem(item, x, y)
		if not item then
			return
		end
		assert(x ~= nil, "'x' position required")
		assert(y ~= nil, "'y' position required")
		local curItem = self:getItemFromPosition(x, y)
		local isSameType = curItem and (curItem.__type == item.__type)
		-- add to stack
		local isStackable = item.maxStackSize > 1
		if (isStackable and isSameType) or (curItem == EMPTY_SLOT) then
			local remaining = self:addItemToInventory(item, {x, y})
			return remaining
			-- swap item stacks since they're different types
		else
			-- pickup current item in slot
			local newPickup = self:pickupItem(x, y)
			self:addItemToInventory(item, {x, y})
			return newPickup
		end
	end

	--[[
		equips and drops the item into the slot

		returns:
			[BOOLEAN] whether the item can be equipped or not
			[TABLE] the current item in the slot
	]]
	function rootStore:equipItem(item, slotX, slotY)
		local category = itemSystem.getDefinition(item).category
		local canEquip, errorMsg = self:canEquiptToSlot(item, slotX, slotY)
		if not canEquip then
			msgBus.send(msgBus.PLAYER_ACTION_ERROR, errorMsg)
			-- local allowedSlotCategory = itemConfig.equipmentGuiSlotMap[slotY][slotX]
			-- local errorMsg = "[EQUIP_ITEM] invalid category `"..category
			return canEquip, errorMsg
		end
		local currentItemInSlot = self:unequipItem(slotX, slotY)
		self:set("equipment", function(state)
			return require'utils.clone-grid'(state.equipment, function(v, x, y)
				local isCurrentlyEquippedSlot = x == slotX and y == slotY
				if isCurrentlyEquippedSlot then
					return item
				end
				return v
			end)
		end)
		return canEquip, currentItemInSlot
	end

	function rootStore:canEquiptToSlot(item, slotX, slotY)
		if not item then
			return false
		end
		local itemDef = itemSystem.getDefinition(item)
		local category = itemDef.category
		local levelRequirement = itemDef.levelRequirement or 0
		local allowedSlotCategory = itemConfig.equipmentGuiSlotMap[slotY][slotX]
		local canEquip = allowedSlotCategory == category and
			rootStore:get().level >= levelRequirement
		if not canEquip then
			if allowedSlotCategory ~= category then
				return false, 'invalid category for slot '..slotY..','..slotX
			end
			return false, 'level requirement not met for item '..itemDef.title
		end
		return canEquip, false
	end

	-- unequips and picks up the item from the slot
	function rootStore:unequipItem(slotX, slotY)
		local currentItem = self:getEquippedItem(slotX, slotY)
		if not currentItem then
			return EMPTY_SLOT
		end
		local categoryAtSlot = itemConfig.equipmentGuiSlotMap[slotY][slotX]
		-- remove item from list by making an immutable copy of the equipment grid and setting the slot value to EMPTY_slot
		self:set("equipment", function(state)
			return require'utils.clone-grid'(state.equipment, function(v, x, y)
				local category = itemConfig.equipmentGuiSlotMap[y][x]
				local isPositionMatch = y == slotY and x == slotX
				local isCategoryMatch = category == categoryAtSlot
				if (isCategoryMatch and isPositionMatch) then
					return EMPTY_SLOT
				end
				return v
			end)
		end)
		return currentItem
	end

	function rootStore:getEquippedItem(slotX, slotY)
		local equipmentRow = self:get().equipment[slotY]
		return equipmentRow and equipmentRow[slotX]
	end
end