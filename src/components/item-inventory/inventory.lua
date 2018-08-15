local Component = require 'modules.component'
local Color = require 'modules.color'
local groups = require 'components.groups'
local config = require 'config'

local InventoryBlueprint = {
  group = groups.gui
}

function InventoryBlueprint.init()
end

local floor = math.floor

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
  local slots = require'utils.make-grid'(11, 9, Color.BLACK)
  self.slots = slots
  self.slotSize = 30
  self.slotMargin = 2
  local w, h = calcInventorySize(slots, self.slotSize, self.slotMargin)
  self.w = w
  self.h = h
end

function InventoryBlueprint.draw(self)
  love.graphics.setColor(1,1,1)
  love.graphics.print('Inventory', 100, 55)
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)

  local w, h = self.w, self.h
  -- center to screen
  local posX = (config.resolution.w - w) / 2
  local posY = (config.resolution.h - h) / 2
  love.graphics.rectangle('fill', posX, posY, w, h)

  drawSlots(posX, posY, self.slots, self.slotSize, self.slotMargin)
end

return Component.createFactory(InventoryBlueprint)