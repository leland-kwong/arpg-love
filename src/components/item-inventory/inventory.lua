local Component = require 'modules.component'
local Color = require 'modules.color'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local pprint = require 'utils.pprint'
local config = require 'config'
local gameScale = config.scaleFactor
local floor = math.floor
local font = require 'components.font'

local guiTextLayerTitle = GuiText.create({
  font = font.secondary.font
})

local guiTextLayerBody = GuiText.create({
  font = font.primary.font
})

local InventoryBlueprint = {
  slots = {},
  group = groups.gui,
}

local function calcInventorySize(slots, slotSize, margin)
  local rows, cols = #slots, #slots[1]
  local height = (rows * slotSize) + (rows * margin) + margin
  local width = (cols * slotSize) + (cols * margin) + margin
  return width, height
end

local animationFactory = require'components.animation-factory'
local itemDefinition = require'components.item-inventory.items.item-definitions'
local itemAnimationsCache = {}

-- centers the box to its parent with origin at north-west
local function boxCenterOffset(w, h, parentW, parentH)
  local x = (parentW - w) / 2
  local y = (parentH - h) / 2
  return x, y
end

local function drawItem(item, x, y, slotSize)
  local d = itemDefinition.getDefinition(item)
  if d then
    local animation = itemAnimationsCache[def]
    if not animation then
      animation = animationFactory:new({
        d.sprite
      })
      itemAnimationsCache[d] = animation
    end

    local sx, sy, sw, sh = animation.sprite:getViewport()
    local ox, oy = boxCenterOffset(sw, sh, slotSize, slotSize)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      animationFactory.atlas,
      animation.sprite,
      x + ox, y + oy
    )
  end
end

function InventoryBlueprint.getSlotPosition(self, x, y, margin)
  local slotSize = self.slotSize
  local inventoryX, inventoryY = self.x, self.y
  local posX, posY = ((x - 1) * slotSize) + (x * margin) + inventoryX,
    ((y - 1) * slotSize) + (y * margin) + inventoryY
  return posX, posY
end

local function insertTestItem(self)
  self.slots[1][3] = require'components.item-inventory.items.definitions.mock-shoes'.create()
end

local function drawTooltip(item, x, y, w2, h2)
  local w, h = 300, 200
  local posX, posY = x + w2, y
  local padding = 12
  local itemDef = itemDefinition.getDefinition(item)
  local tooltipContent = itemDef.tooltip(item)

  -- title
  guiTextLayerTitle:add(itemDef.title, Color.WHITE, posX + padding, posY + padding)
  local titleW, titleH = GuiText.getTextSize(itemDef.title, guiTextLayerTitle.font)

  -- rarity
  local itemGuiConfig = require'components.item-inventory.items.config'
  local rarity = itemDef.rarity
  local rarityTextCopy = itemGuiConfig.rarityTitle[rarity] ..' '.. itemGuiConfig.categoryTitle[itemDef.category]
  local rarityX, rarityY = posX + padding,
    posY + padding + titleH + titleH
  guiTextLayerBody:add(
    rarityTextCopy,
    itemGuiConfig.rarityColor[rarity],
    rarityX, rarityY
  )
  local rarityW, rarityH = GuiText.getTextSize(rarityTextCopy, guiTextLayerBody.font)

  -- stats
  local tooltipContentY = rarityY + (rarityH * 2)
  guiTextLayerBody:addTextGroup(
    tooltipContent,
    posX + padding,
    tooltipContentY
  )

  -- background
  local bodyCopyW, bodyCopyH = guiTextLayerBody.textGraphic:getDimensions()
  local maxWidth = math.max(titleW, rarityW, bodyCopyW) + (padding * 2) -- include side padding
  local totalHeight = tooltipContentY
  local bgColor = 0.15
  love.graphics.setColor(bgColor, bgColor, bgColor)
  love.graphics.rectangle(
    'fill',
    posX, posY,
    maxWidth,
    totalHeight - padding
  )
  local outlineColor = bgColor * 2
  love.graphics.setColor(outlineColor, outlineColor, outlineColor)
  love.graphics.rectangle(
    'line',
    posX, posY,
    maxWidth,
    totalHeight - padding
  )
end

-- sets up interactable gui nodes and renders the contents in each slot
function InventoryBlueprint.setupSlotInteractions(self, slots, margin)
  require'utils.iterate-grid'(slots, function(item, gridX, gridY)
    local posX, posY = self:getSlotPosition(gridX, gridY, margin)

    Gui.create({
      x = posX,
      y = posY,
      w = self.slotSize,
      h = self.slotSize,
      type = Gui.types.INTERACT,
      drawOrder = function(self)
        if self.hovered then
          return 5
        end
        return 4
      end,
      render = function(self)
        if self.hovered then
          love.graphics.setColor(0.7,0.7,0,1)
        else
          love.graphics.setColor(0,0,0,1)
        end
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        drawItem(item, self.x, self.y, self.w)

        if self.hovered then
          if item then
            drawTooltip(item, self.x, self.y, self.w, self.h)
          end
        end
      end
    })
  end)
end

function InventoryBlueprint.init(self)
  insertTestItem(self)

  self.slotSize = 30
  self.slotMargin = 2
  local w, h = calcInventorySize(self.slots, self.slotSize, self.slotMargin)
  self.w = w
  self.h = h

  -- center to screen
  self.x = (config.resolution.w - w) / 2
  self.y = (config.resolution.h - h) / 2

  self:setupSlotInteractions(self.slots, self.slotMargin)
end

local function drawTitle(self, x, y)
  guiTextLayerTitle:add('Inventory', Color.WHITE, x, y)
end

function InventoryBlueprint.draw(self)
  local w, h = self.w, self.h

  drawTitle(self, self.x, 20)

  -- inventory background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle('fill', self.x, self.y, w, h)
end

return Component.createFactory(InventoryBlueprint)