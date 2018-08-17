local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local GuiText = require 'components.gui.gui-text'
local config = require 'config'
local font = require 'components.font'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local animationFactory = require'components.animation-factory'
local itemDefinition = require'components.item-inventory.items.item-definitions'
local itemAnimationsCache = {}

local guiStackSizeTextLayer = GuiText.create({
  font = font.primary.font,
  drawOrder = function()
    return 5
  end
})

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
    local ox, oy = boxCenterOffset(
      sw, sh,
      slotSize or sw, slotSize or sh
    )
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      animationFactory.atlas,
      animation.sprite,
      x + ox, y + oy
    )

    local showStackSize = item.stackSize > 1
    if showStackSize then
      guiStackSizeTextLayer:add(item.stackSize, Color.WHITE, x + ox, y + oy)
    end
  end
end

local function getSlotPosition(gridX, gridY, offsetX, offsetY, slotSize, margin)
  local posX, posY = ((gridX - 1) * slotSize) + (gridX * margin) + offsetX,
    ((gridY - 1) * slotSize) + (gridY * margin) + offsetY
  return posX, posY
end

local function drawTooltip(item, x, y, w2, h2)
  local posX, posY = x, y
  local padding = 12
  local itemDef = itemDefinition.getDefinition(item)
  local tooltipContent = itemDef.tooltip(item)

  --[[
    IMPORTANT: We must do the tooltip content dimension calculations first to see if the tooltip
      will go out of view. And if it does, we'll call this function again with the adjust positions.
  ]]

  -- title text and dimensions
  local titleW, titleH = GuiText.getTextSize(itemDef.title, guiTextLayers.title.font)

  -- rarity text and dimensions
  local itemGuiConfig = require'components.item-inventory.items.config'
  local rarity = itemDef.rarity
  local rarityTitle = itemGuiConfig.rarityTitle[rarity]
  local rarityTextCopy = (rarityTitle and rarityTitle ..' ' or '').. itemGuiConfig.categoryTitle[itemDef.category]
  local rarityX, rarityY = posX + padding,
    posY + padding + titleH + titleH
  local rarityW, rarityH = GuiText.getTextSize(rarityTextCopy, guiTextLayers.body.font)

  -- body text and dimensions
  local bodyCopyW, bodyCopyH = GuiText.getTextSize(tooltipContent, guiTextLayers.body.font)

  -- total tooltip height
  local totalHeight = (titleH + titleH) + (rarityH + rarityH) + bodyCopyH + (padding * 2)

  local isBottomOutOfView = posY + totalHeight > config.resolution.h
  if isBottomOutOfView then
    -- flip the tooltip vertically so that its pivot is on the south side
    return drawTooltip(item, x, y - totalHeight + h2, w2, h2)
  end

  -- title
  guiTextLayers.title:add(itemDef.title, Color.WHITE, posX + padding, posY + padding)

  -- rarity
  guiTextLayers.body:add(
    rarityTextCopy,
    itemGuiConfig.rarityColor[rarity],
    rarityX, rarityY
  )

  -- stats
  local tooltipContentY = rarityY + (rarityH * 2)
  guiTextLayers.body:addTextGroup(
    tooltipContent,
    posX + padding,
    tooltipContentY
  )

  -- background
  local maxWidth = math.max(titleW, rarityW, bodyCopyW) + (padding * 2) -- include side padding

  local bgColor = 0.15
  love.graphics.setColor(bgColor, bgColor, bgColor)
  love.graphics.rectangle(
    'fill',
    posX, posY,
    maxWidth,
    totalHeight
  )

  local outlineColor = bgColor * 2
  love.graphics.setColor(outlineColor, outlineColor, outlineColor)
  love.graphics.rectangle(
    'line',
    posX, posY,
    maxWidth,
    totalHeight
  )
end

local itemPickedUp = nil
local function itemSlotPickupAndDrop(item, x, y, rootStore)
  local curPickedUpItem = itemPickedUp
  -- if an item is already picked up, then we want to drop it
  -- itemPickedUp = (not itemPickedUp) and item or nil
  local isPickingUp = itemPickedUp == nil
  if isPickingUp then
    itemPickedUp = rootStore:pickupItem(x, y)
  -- drop picked up item to slot
  elseif curPickedUpItem then
    local itemSwap = rootStore:dropItem(curPickedUpItem, x, y)
    itemPickedUp = itemSwap
  end
end

-- sets up interactable gui nodes and renders the contents in each slot
local function setupSlotInteractions(self, getSlots, margin)
  local rootStore = self.rootStore
  local initialSlots = getSlots()
  -- setup the grid interaction
  require'utils.iterate-grid'(initialSlots, function(_, gridX, gridY)
    local posX, posY = getSlotPosition(gridX, gridY, self.x, self.y, self.slotSize, margin)
    -- we must get the item dynamically since the slots change when moving/deleting items around the inventory
    local function getItem()
      return getSlots()[gridY][gridX]
    end

    local slotSize = self.slotSize
    Gui.create({
      x = posX,
      y = posY,
      w = slotSize,
      h = slotSize,
      type = Gui.types.INTERACT,
      onUpdate = function(self)
        -- create a tooltip
        local item = getItem()
        if self.hovered and item and (not self.tooltip) then
          self.tooltip = Gui.create({
            x = posX + self.w,
            y = posY,
            draw = function(self)
              drawTooltip(item, self.x, self.y, slotSize, slotSize)
            end,
            drawOrder = function()
              return 6
            end
          }):setParent(self)
        end

        -- cleanup tooltip
        if (not self.hovered) and self.tooltip then
          self.tooltip:delete()
          self.tooltip = nil
        end
      end,
      onClick = function(self)
        itemSlotPickupAndDrop(getItem(), gridX, gridY, rootStore)
      end,
      drawOrder = function(self)
        return 3
      end,
      render = function(self)
        if self.hovered then
          love.graphics.setColor(0.7,0.7,0,1)
        else
          love.graphics.setColor(0,0,0,1)
        end
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        local item = getItem()
        drawItem(item, self.x, self.y, self.w)
      end
    }):setParent(self)
  end)

  -- handles the picked up item and makes it follow the cursor
  Gui.create({
    type = Gui.types.INTERACT,
    draw = function()
      if itemPickedUp then
        local gameScale = config.scaleFactor
        local mx, my = love.mouse.getX() / gameScale, love.mouse.getY() / gameScale
        drawItem(itemPickedUp, mx - self.slotSize/4, my - self.slotSize/4)
      end
    end,
    drawOrder = function()
      return 4
    end
  })
end

return setupSlotInteractions