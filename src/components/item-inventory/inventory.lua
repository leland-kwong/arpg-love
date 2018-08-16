local Component = require 'modules.component'
local Color = require 'modules.color'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local config = require 'config'
local gameScale = config.scaleFactor
local floor = math.floor

local InventoryBlueprint = {
  slots = {},
  group = groups.gui
}

local function calcInventorySize(slots, slotSize, margin)
  local rows, cols = #slots, #slots[1]
  local height = (rows * slotSize) + (rows * margin) + margin
  local width = (cols * slotSize) + (cols * margin) + margin
  return width, height
end

local function drawSlots(inventoryX, inventoryY, slots, slotSize, margin)
  local rows, cols = #slots, #slots[1]
  for y=1, rows do
    for x=1, cols do
      love.graphics.setColor(Color.BLACK)
      love.graphics.rectangle(
        'fill',
        ((x - 1) * slotSize) + (x * margin) + inventoryX,
        ((y - 1) * slotSize) + (y * margin) + inventoryY,
        slotSize,
        slotSize
      )
    end
  end
end

function InventoryBlueprint.init(self)
  self.slotSize = 30
  self.slotMargin = 2
  local w, h = calcInventorySize(self.slots, self.slotSize, self.slotMargin)
  self.w = w
  self.h = h

  self.guiTextLayer = GuiText.create()
end

local function title(self, x, y)
  self.guiTextLayer:add('Inventory', Color.WHITE, x, y)
end

function InventoryBlueprint.draw(self)
  local w, h = self.w, self.h
  -- center to screen
  local posX = (config.resolution.w - w) / 2
  local posY = (config.resolution.h - h) / 2

  title(self, posX, 20)

  -- inventory background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', posX, posY, w, h)

  -- inventory slots
  drawSlots(posX, posY, self.slots, self.slotSize, self.slotMargin)
end

return Component.createFactory(InventoryBlueprint)