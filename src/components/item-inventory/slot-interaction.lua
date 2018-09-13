local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'
local font = require 'components.font'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local animationFactory = require'components.animation-factory'
local itemDefinition = require'components.item-inventory.items.item-definitions'
local Position = require 'utils.position'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local boxCenterOffset = Position.boxCenterOffset
local drawItem = require 'components.item-inventory.draw-item'
local Lru = require 'utils.lru'

local spriteCache = Lru.new(100)
-- returns a static sprite for drawing
local function getSprite(name)
  local sprite = spriteCache:get(name)
  if (not sprite) then
    sprite = animationFactory:new({ name })
    spriteCache:set(name, sprite)
  end
  return sprite
end

-- currently picked up item. We can only have one item picked up at a time
local itemPickedUp = nil
local isDropModeFloor = false

msgBus.subscribe(function(msgType, message)
  if msgBus.INVENTORY_DROP_MODE_INVENTORY == msgType or
    msgBus.INVENTORY_DROP_MODE_FLOOR == msgType then
      isDropModeFloor = msgBus.INVENTORY_DROP_MODE_FLOOR == msgType
  end
end)

-- handles dropping items on the floor when its in the floor drop mode
Component.createFactory({
  group = groups.gui,
  init = function(self)
    msgBus.subscribe(function(msgType, msgValue)
      if isDropModeFloor and
        msgBus.MOUSE_PRESSED == msgType and
        itemPickedUp
      then
        msgBus.send(msgBus.DROP_ITEM_ON_FLOOR, itemPickedUp)
        itemPickedUp = nil
      end
    end)
  end
}).create()

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
  local tooltipItemUpgrade = itemDef.tooltipItemUpgrade(item)

  --[[
    IMPORTANT: We must do the tooltip content dimension calculations first to see if the tooltip
      will go out of view. And if it does, we'll call this function again with the adjusted positions.
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

  -- item upgrade content and dimensions
  local itemUpgradeW, itemUpgradeH = 200, 200

  -- total tooltip height
  local totalHeight = (titleH + titleH) +
                      (rarityH + rarityH) +
                      bodyCopyH +
                      itemUpgradeH +
                      (padding * 2)

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
  local maxWidth = math.max(titleW, rarityW, bodyCopyW, itemUpgradeW) + (padding * 2) -- include side padding

  local bgColor = 0
  love.graphics.setColor(bgColor, bgColor, bgColor, 0.9)
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

  -- [item upgrades]
  if tooltipItemUpgrade then
    local tooltipStartX = posX + padding
    local upgradePanelPosY = tooltipContentY + bodyCopyH + 20
    local titleTextLayer = guiTextLayers.body
    local titleW, titleH = GuiText.getTextSize('test title', titleTextLayer.font)

    -- upgrade experience bar
    local experienceBarWidth, experienceBarHeight = 10, 170
    local iconWidth, iconHeight = 13, 13
    local experienceBarPosY = upgradePanelPosY
    local lastUpgrade = tooltipItemUpgrade[#tooltipItemUpgrade]
    local expfillPercentage = item.experience / lastUpgrade.experienceRequired
    local expBarPosX = tooltipStartX
    expfillPercentage = expfillPercentage > 1 and 1 or expfillPercentage
    -- experience bar unfilled background
    love.graphics.setColor(0.1,0.1,0.1)
    love.graphics.rectangle('fill', expBarPosX, experienceBarPosY, experienceBarWidth, experienceBarHeight)
    -- experience progress fill
    love.graphics.setColor(1,0.8,0)
    love.graphics.rectangle(
      'fill', expBarPosX, experienceBarPosY,
      experienceBarWidth,
      (experienceBarHeight * expfillPercentage)
    )
    -- experience bar border
    love.graphics.setColor(0.4,0.4,0.4)
    love.graphics.rectangle(
      'line', expBarPosX, experienceBarPosY,
      experienceBarWidth, experienceBarHeight
    )

    local upgradeCount = #tooltipItemUpgrade
    for i=1, #tooltipItemUpgrade do
      local upgradeItem = tooltipItemUpgrade[i]
      local expReq = upgradeItem.experienceRequired
      local percentReq = expReq / lastUpgrade.experienceRequired
      local positionIndex = i - 1
      local segmentY = math.ceil(experienceBarPosY + (percentReq * experienceBarHeight))
      local isUnlocked = item.experience >= expReq

      local isLastItem = i == upgradeCount
      if not isLastItem then
        -- exp requirement line
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.4,0.4,0.4)
        love.graphics.line(expBarPosX + 1, segmentY, expBarPosX + experienceBarWidth - 1, segmentY)
      end

      -- upgrade graphic
      local iconPosX = tooltipStartX + experienceBarWidth + 5
      local iconPosY = segmentY - (iconHeight/2)
      local opacity = isUnlocked and 1 or 0.4
      love.graphics.setColor(1, 1, 1, opacity)
      love.graphics.draw(
        animationFactory.atlas,
        getSprite(upgradeItem.sprite).sprite,
        iconPosX,
        iconPosY
      )

      -- upgrade title
      local titlePosX = iconPosX + iconWidth + 5
      local titlePosY = iconPosY + 2
      titleTextLayer:add(
        upgradeItem.title,
        Color.WHITE,
        titlePosX,
        titlePosY
      )

      if (not isUnlocked) then
        -- upgrade experience help text
        local titleW, titleH = GuiText.getTextSize(upgradeItem.title, titleTextLayer.font)
        local descPosX = titlePosX
        local descPosY = titlePosY + titleH + 5
        local expRequirementDiff = upgradeItem.experienceRequired - item.experience
        guiTextLayers.body:add(
          expRequirementDiff .. ' experience to unlock',
          Color.MED_GRAY,
          descPosX,
          descPosY
        )
      end
    end
  end
end

-- handles the picked up item and makes it follow the cursor
Gui.create({
  type = Gui.types.INTERACT,
  draw = function()
    if itemPickedUp then
      local gameScale = config.scaleFactor
      local mx, my = love.mouse.getX() / gameScale, love.mouse.getY() / gameScale
      local sprite = itemDefinition.getDefinition(itemPickedUp).sprite
      local sw, sh = animationFactory:getSpriteSize(sprite, true)
      drawItem(itemPickedUp, mx - sw/2, my - sh/2)
    end
  end,
  drawOrder = function()
    return 4
  end
})

-- sets up interactable gui nodes and renders the contents in each slot
local function setupSlotInteractions(
  self, getSlots, margin,
  onItemPickupFromSlot, onItemDropToSlot, onItemActivate,
  slotRenderer
)
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
      onClick = function(self, rightClick)
        if rightClick then
          local item = getItem()
          local d = itemDefinition.getDefinition(item)
          if d and onItemActivate then
            onItemActivate(item)
          end
          return
        end
        local x, y = gridX, gridY
        local curPickedUpItem = itemPickedUp
        -- if an item hasn't already been picked up, then we're in pickup mode
        local isPickingUp = (not itemPickedUp)
        if isPickingUp then
          itemPickedUp = onItemPickupFromSlot(x, y)
        -- drop picked up item to slot
        elseif curPickedUpItem then
          local itemSwap = onItemDropToSlot(curPickedUpItem, x, y)
          itemPickedUp = itemSwap
        end
      end,
      drawOrder = function(self)
        return 3
      end,
      render = function(self)
        if self.hovered then
          love.graphics.setColor(1,1,1,0.5)
        else
          love.graphics.setColor(0,0,0,0.5)
        end
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

        local item = getItem()
        if slotRenderer then
          slotRenderer(item, self.x, self.y, gridX, gridY, self.w, self.h)
        end

        drawItem(item, self.x, self.y, self.w)
      end
    }):setParent(self)
  end)
end

return setupSlotInteractions