local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local config = require 'config'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local setupSlotInteractions = require 'components.item-inventory.slot-interaction'

local InventoryBlueprint = {
  rootStore = nil, -- game state
  slots = {},
  group = groups.gui,
  onDisableRequest = require'utils.noop'
}

local function calcInventorySize(slots, slotSize, margin)
  local rows, cols = #slots, #slots[1]
  local height = (rows * slotSize) + (rows * margin) + margin
  local width = (cols * slotSize) + (cols * margin) + margin
  return width, height
end

local function setupCloseHotkey(self)
  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.KEY_RELEASED == msgType then
      local key = msgValue.key
      if key == config.keyboard.INVENTORY_TOGGLE then
        self:delete(true)
        return msgBus.CLEANUP
      end
    end
  end)
end

local function insertTestItems(self)
  local item1 = require'components.item-inventory.items.definitions.mock-shoes'.create()
  local item2 = require'components.item-inventory.items.definitions.mock-shoes'.create()
  self.rootStore:addItemToInventory(item1, {3, 1})
  self.rootStore:addItemToInventory(item2, {4, 1})
  self.rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.mock-armor'.create()
    , {5, 1})
  self.rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.gpow-armor'.create()
    , {5, 2})
  self.rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {1, 1})
  self.rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {2, 1})
  self.rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {2, 1})
  for i=1, 99 do
    self.rootStore:addItemToInventory(
      require'components.item-inventory.items.definitions.potion-health'.create(),
      {2, 2})
  end
end

function InventoryBlueprint.init(self)
  insertTestItems(self)
  setupCloseHotkey(self)

  self.slotSize = 30
  self.slotMargin = 2

  local w, h = calcInventorySize(self.slots(), self.slotSize, self.slotMargin)
  self.w = w
  self.h = h

  -- center to screen
  local offsetRight = 20
  self.x = (config.resolution.w - w) - offsetRight
  self.y = (config.resolution.h - h) / 2

  local function inventoryOnItemPickupFromSlot(x, y)
    return self.rootStore:pickupItem(x, y)
  end

  local function inventoryOnItemDropToSlot(curPickedUpItem, x, y)
    return self.rootStore:dropItem(curPickedUpItem, x, y)
  end

  setupSlotInteractions(
    self,
    self.slots,
    self.slotMargin,
    inventoryOnItemPickupFromSlot,
    inventoryOnItemDropToSlot
  )

  local equipmentW, equipmentH = 100, h
  local EquipmentPanel = require 'components.item-inventory.equipment-panel'
  EquipmentPanel.create({
    rootStore = self.rootStore,
    x = self.x - equipmentW - 5,
    y = self.y,
    w = equipmentW,
    h = h,
    slotSize = self.slotSize
  }):setParent(self)
end

local function drawTitle(self, x, y)
  guiTextLayers.title:add('Inventory', Color.WHITE, x, y)
end

function InventoryBlueprint.draw(self)
  local w, h = self.w, self.h

  drawTitle(self, self.x, 20)

  -- inventory background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', self.x, self.y, w, h)
end

function InventoryBlueprint.final(self)
  self.onDisableRequest()
end

return Component.createFactory(InventoryBlueprint)