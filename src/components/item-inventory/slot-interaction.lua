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

local signHumanized = function(v)
  return v >= 0 and "+" or "-"
end

local modifierParsers = {
  attackTimeReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' attack time reduction'
    }
  end,
  maxEnergy = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' maximum energy'
    }
  end,
  maxHealth = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' maximum health'
    }
  end,
  healthRegeneration = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' health regeneration'
    }
  end,
  energyRegeneration = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' energy regeneration'
    }
  end,
  flatDamage = function(value)
    return {
      Color.CYAN, signHumanized(value)..value,
      Color.WHITE, ' physical damage'
    }
  end,
  weaponDamage = function(value)
    return {
      Color.CYAN, value,
      Color.WHITE, ' weapon damage'
    }
  end,
  percentDamage = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, '% weapon damage'
    }
  end,
  armor = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' armor'
    }
  end,
  moveSpeed = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' movement speed'
    }
  end,
  coldResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' cold reistance'
    }
  end,
  lightningResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' lightning resistance'
    }
  end,
  fireResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' fire resistance'
    }
  end,
  flatPhysicalDamageReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' physical damage reduction'
    }
  end,
  cooldownReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' cooldown reduction'
    }
  end,
  energyCostReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' energy cost reduction'
    }
  end,
  experienceMultiplier = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' experience gain'
    }
  end
}

local function concatTable(a, b)
  if not b then
    return a
  end
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

local baseModifiers = require 'components.state.base-stat-modifiers'()
local function parseItemModifiers(item)
  local modifiers = {}
  for k,_ in pairs(baseModifiers) do
    local parser = modifierParsers[k]
    if parser then
      if item[k] then
        local v = item[k]
        local output = parser(v)
        local length = #output
        for i=1, length, 2 do
          local color = output[i]
          local str = output[i + 1]
          local isLastItem = i == length - 1
          if isLastItem then
            str = str..'\n'
          end
          table.insert(modifiers, color)
          table.insert(modifiers, str)
        end
      end
    else
      error('no parser for property '..k)
    end
  end
  return modifiers
end

local function drawTooltip(item, x, y, w2, h2, rootStore)
  local posX, posY = x, y
  local padding = 12
  local itemDef = itemDefinition.getDefinition(item)
  local tooltipContent = itemDef.tooltip(item)
  local tooltipItemUpgrade = itemDef.upgrades
  local tooltipModifierValues = parseItemModifiers(item)
  local levelRequirementText = itemDef.levelRequirement and 'Required level: '..itemDef.levelRequirement or nil
  tooltipContent = concatTable(tooltipModifierValues, tooltipContent)

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

  local levelRequirementW, levelRequirementH = 0, 0
  if levelRequirementText then
    levelRequirementW, levelRequirementH = GuiText.getTextSize(itemDef.levelRequirement or '', guiTextLayers.body.font)
  end

  -- body text and dimensions
  local bodyCopyW, bodyCopyH = GuiText.getTextSize(tooltipContent, guiTextLayers.body.font)

  -- item upgrade content and dimensions
  local itemUpgradeW, itemUpgradeH = 200, 200
  if not tooltipItemUpgrade then
    itemUpgradeW, itemUpgradeH = 0, 0
  end

  -- total tooltip height
  local totalHeight = (titleH + titleH) +
                      (rarityH * 2) +
                      (levelRequirementH * 2) +
                      bodyCopyH +
                      itemUpgradeH +
                      (padding * 2)
  local maxWidth = math.min(
    200,
    math.max(titleW, rarityW, bodyCopyW, itemUpgradeW) -- include side padding
  )
  local bottomOutOfView = (posY + totalHeight) - config.resolution.h
  local isBottomOutOfView = bottomOutOfView > 0
  if isBottomOutOfView then
    -- shift tooltip vertically so that it stays within viewport
    return drawTooltip(item, x, y - bottomOutOfView - 5, w2, h2)
  end

  -- title
  local completeTitle = (item.prefixName and item.prefixName..' ' or '') .. itemDef.title .. (item.suffixName and item.suffixName..' ' or '')
  guiTextLayers.title:add(completeTitle, Color.WHITE, posX + padding, posY + padding)

  -- rarity
  guiTextLayers.body:add(
    rarityTextCopy,
    itemGuiConfig.rarityColor[rarity],
    rarityX, rarityY
  )

  local levelRequirementY = rarityY + (rarityH * 2)
  local requirementNotMet = rootStore:get().level < (itemDef.levelRequirement or 0)
  if requirementNotMet then
    guiTextLayers.body:addf(
      {
        Color.WHITE, 'level requirement: ',
        Color.RED, itemDef.levelRequirement
      },
      maxWidth,
      'left',
      posX + padding,
      levelRequirementY
    )
  else
    guiTextLayers.body:add(
      levelRequirementText,
      Color.WHITE,
      posX + padding,
      levelRequirementY
    )
  end

  -- stats
  local tooltipContentY = levelRequirementY + (levelRequirementH * 2)
  guiTextLayers.body:addf(
    tooltipContent,
    maxWidth,
    'left',
    posX + padding,
    tooltipContentY
  )

  -- background
  local bgWidth = maxWidth + padding
  local bgColor = 0
  love.graphics.setColor(bgColor, bgColor, bgColor, 0.9)
  love.graphics.rectangle(
    'fill',
    posX, posY,
    bgWidth,
    totalHeight
  )

  local outlineColor = 0.2
  love.graphics.setColor(outlineColor, outlineColor, outlineColor, 0.9)
  love.graphics.rectangle(
    'line',
    posX, posY,
    bgWidth,
    totalHeight
  )

  -- [item upgrades]
  if tooltipItemUpgrade then
    local tooltipStartX = posX + padding
    local upgradePanelPosY = tooltipContentY + bodyCopyH + 20
    local titleTextLayer = guiTextLayers.body
    local titleW, titleH = GuiText.getTextSize('test title', titleTextLayer.font)

    -- upgrade experience bar
    local experienceBarWidth, experienceBarHeight = 10, 160
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
      local upgradeItemSprite = getSprite(
        upgradeItem.sprite or 'item-upgrade-placeholder-unlocked'
      ).sprite
      love.graphics.setColor(1, 1, 1, opacity)
      love.graphics.draw(
        animationFactory.atlas,
        upgradeItemSprite,
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
              drawTooltip(item, self.x, self.y, slotSize, slotSize, rootStore)
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