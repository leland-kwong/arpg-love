local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local setupSlotInteractions = require 'components.item-inventory.slot-interaction'
local itemConfig = require 'components.item-inventory.items.config'
local itemSystem =require("components.item-inventory.items.item-system")
local Sound = require 'components.sound'
local MenuManager = require 'modules.menu-manager'

local iContext = 'InventoryMenu'

local InventoryBlueprint = {
  id = 'MENU_INVENTORY',
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

local function InteractArea(self)
  return Gui.create({
		x = self.x,
		y = self.y,
		w = self.w,
    h = self.h,
    onPointerMove = function()
			msgBus.send(msgBus.INVENTORY_DROP_MODE_INVENTORY)
		end,
		onPointerLeave = function()
			msgBus.send(msgBus.INVENTORY_DROP_MODE_FLOOR)
		end
	})
end

msgBus.on(msgBus.ALL, function(msg, msgType)
  local rootStore = require 'main.global-state'.gameState

  if msgBus.EQUIPMENT_SWAP == msgType then
    local item = msg
    rootStore:equipmentSwap(item)
    msgBus.send(msgBus.EQUIPMENT_CHANGE)
  end

  if msgBus.INVENTORY_PICKUP == msgType or
    msgBus.EQUIPMENT_SWAP == msgType
  then
    love.audio.stop(Sound.INVENTORY_PICKUP)
    love.audio.play(Sound.INVENTORY_PICKUP)
  end

  if msgBus.INVENTORY_DROP == msgType then
    love.audio.stop(Sound.INVENTORY_DROP)
    love.audio.play(Sound.INVENTORY_DROP)
  end
end)

function InventoryBlueprint.init(self)
  local msgBusMainMenu = require 'components.msg-bus-main-menu'
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  MenuManager.clearAll()
  MenuManager.push(self)

  self.slotSize = 30
  self.slotMargin = 2

  local w, h = calcInventorySize(self.slots(), self.slotSize, self.slotMargin)
  local panelMargin = 5
  local statsWidth, statsHeight = 165, h
  local equipmentWidth, equipmentHeight = 100, h
  self.w = w
  self.h = h

  -- center to screen
  local inventoryX = require'utils.position'.boxCenterOffset(
    w + (equipmentWidth + panelMargin) + (statsWidth + panelMargin), h,
    love.graphics.getWidth() / config.scaleFactor, love.graphics.getHeight() / config.scaleFactor
  )
  inventoryX = inventoryX - 100
  self.x = inventoryX + equipmentWidth + panelMargin + statsWidth + panelMargin
  self.y = 60

  InteractArea(self):setParent(self)

  local function inventoryOnItemPickupFromSlot(x, y)
    msgBus.send(msgBus.INVENTORY_PICKUP)
    return self.rootStore:pickupItem(x, y)
  end

  local function inventoryOnItemDropToSlot(curPickedUpItem, x, y)
    msgBus.send(msgBus.INVENTORY_DROP)
    return self.rootStore:dropItem(curPickedUpItem, x, y)
  end

  local function inventoryOnItemActivate(item)
    local onActivate = itemSystem.loadModule(item.onActivate).active
    onActivate(item)
  end

  setupSlotInteractions(
    self,
    self.slots,
    self.slotMargin,
    inventoryOnItemPickupFromSlot,
    inventoryOnItemDropToSlot,
    inventoryOnItemActivate
  )

  local EquipmentPanel = require 'components.item-inventory.equipment-panel'
  EquipmentPanel.create({
    rootStore = self.rootStore,
    x = self.x - equipmentWidth - panelMargin,
    y = self.y,
    w = equipmentWidth,
    h = h,
    slotSize = self.slotSize,
    rootStore = self.rootStore
  }):setParent(self)

  local PlayerStatsPanel = require'components.item-inventory.player-stats-panel'
  PlayerStatsPanel.create({
    x = self.x - equipmentWidth - panelMargin - statsWidth - panelMargin,
    y = self.y,
    w = statsWidth,
    h = statsHeight,
    rootStore = self.rootStore
  }):setParent(self)
end

local function drawTitle(self, x, y)
  guiTextLayers.title:add('Inventory', Color.WHITE, x, y)
end

function InventoryBlueprint.draw(self)
  local w, h = self.w, self.h

  drawTitle(self, self.x, self.y - 15)

  -- inventory background
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle('fill', self.x, self.y, w, h)
  love.graphics.setColor(Color.multiplyAlpha(Color.SKY_BLUE, 0.5))
  love.graphics.rectangle('line', self.x, self.y, w, h)
end

function InventoryBlueprint.final(self)
  msgBus.send(msgBus.INVENTORY_DROP_MODE_FLOOR)
  MenuManager.pop()
end

return Component.createFactory(InventoryBlueprint)