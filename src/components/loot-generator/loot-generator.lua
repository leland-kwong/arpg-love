local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local itemSystem =require 'components.item-inventory.items.item-system'
local itemConfig = require 'components.item-inventory.items.config'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local camera = require 'components.camera'
local CreateStore = require 'components.state.state'
local msgBus = require 'components.msg-bus'
local tick = require 'utils.tick'
local tween = require 'modules.tween'
local bump = require 'modules.bump'
local collisionGroups = require 'modules.collision-groups'
local drawOrders = require 'modules.draw-orders'
require 'components.groups.clock'

local eventPriority = 1
local itemGroup = groups.all
local tooltipCollisionWorld = bump.newWorld(16)
local droppedItemsCollisionWorld = bump.newWorld(16)
local function itemMousePosition()
  return camera:getMousePosition()
end

local outlineColor = {1,1,1,1}
local Shaders = require 'modules.shaders'
local shader = Shaders('pixel-outline.fsh')
local atlasData = AnimationFactory.atlasData

local DRAW_ORDER_BACKGROUND = drawOrders.FloorItemTooltip
local DRAW_ORDER_TEXT = drawOrders.FloorItemTooltip + 1
local itemNameTextLayer = GuiText.create({
  group = itemGroup,
  font = require 'components.font'.primary.font,
  drawOrder = function(self)
    return DRAW_ORDER_TEXT
  end
})

local itemNamesTooltipLayer = Gui.create({
  group = itemGroup,
  tooltipPadding = 2,
  drawOrder = function(self)
    return DRAW_ORDER_BACKGROUND
  end,
  onCreate = function(self)
    self.cache = {}
  end,
  add = function(self, item, x, y, itemParent)
    y = y - 16 -- start above the item
    local isNew = self.cache[item] == nil
    self.cache[item] = self.cache[item] or {
      hovered = false,
      itemParent = itemParent
    }
    local tooltip = self.cache[item]
    local hasChangedPosition = x ~= tooltip.lastX or y ~= tooltip.lastY
    tooltip.hasChangedPosition = hasChangedPosition
    tooltip.lastX = x
    tooltip.lastY = y

    local def = itemSystem.getDefinition(item)
    local bgWidth, bgHeight = GuiText.getTextSize(def.title, itemNameTextLayer.font)
    local ttWidth, ttHeight = bgWidth + self.tooltipPadding,
      bgHeight + self.tooltipPadding

    if not hasChangedPosition then
      return
    else
      tooltip.x = x - ttWidth/2 + itemParent.w/2
      tooltip.y = y
    end

    if isNew then
      tooltipCollisionWorld:add(
        tooltip,
        tooltip.x,
        tooltip.y,
        ttWidth,
        ttHeight
      )

      tooltip.gui = Gui.create({
        group = itemGroup,
        eventPriority = eventPriority,
        x = tooltip.x,
        y = tooltip.y,
        w = ttWidth,
        h = ttHeight,
        getMousePosition = itemMousePosition,
        inputContext = 'loot',
        onPointerMove = function()
          msgBus.send(msgBus.ITEM_HOVERED, itemParent)
        end,
        onUpdate = function(self)
          tooltip.hovered = self.hovered
        end
      })
    end
  end,
  delete = function(self, item)
    local tooltip = self.cache[item]
    self.cache[item] = nil
    if tooltip then
      tooltipCollisionWorld:remove(tooltip)
      tooltip.gui:delete()
    end
  end,
  onUpdate = function(self)
    local floor = math.floor
    for item, tooltip in pairs(self.cache) do
      if tooltip.hasChangedPosition then
        local actualX, actualY, cols, len = tooltipCollisionWorld:move(tooltip, tooltip.x, tooltip.y)
        tooltip.x = floor(actualX)
        tooltip.y = floor(actualY)
        tooltip.gui:setPosition(tooltip.x, tooltip.y)
      end
      tooltip.hovered = tooltip.hovered or tooltip.itemParent.hovered
    end
  end,
  draw = function(self)
    for item, tooltip in pairs(self.cache) do
      local def = itemSystem.getDefinition(item)
      local itemName = def.title
      local textColor = itemConfig.rarityColor[item.rarity]
      local bgWidth, bgHeight = GuiText.getTextSize(itemName, itemNameTextLayer.font)
      local paddingX = self.tooltipPadding + 2
      local paddingY = self.tooltipPadding

      love.graphics.setColor(0,0,0,0.4)
      love.graphics.rectangle(
        'fill',
        tooltip.x,
        tooltip.y,
        bgWidth + paddingX,
        bgHeight + paddingY
      )
      itemNameTextLayer:add(itemName, textColor, tooltip.x + paddingX/2, tooltip.y + paddingY/2 + 1)

      if tooltip.hovered then
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle(
          'line',
          tooltip.x,
          tooltip.y,
          bgWidth + paddingX,
          bgHeight + paddingY
        )
      end
    end
  end
})

local function dropItemCollisionFilter(item)
  local collisionGroups = require 'modules.collision-groups'
  return collisionGroups.matches(item.group, collisionGroups.create('floorItem', 'obstacle'))
end

local LootGenerator = {
  group = itemGroup,
  isNew = true,
  rootStore = CreateStore,
  class = collisionGroups.floorItem,
  -- item to generate
  item = nil,
}

-- parabola that goes up and back down
local dropHeight = 8

local function drawLegendaryItemEffect(self, x, y, angle)
  local calcPulse = require 'utils.math'.calcPulse

  local opacity = calcPulse(2, self.clock) + 0.1
  local Color = require 'modules.color'
  love.graphics.setColor(Color.multiplyAlpha(Color.RARITY_LEGENDARY, opacity))

  -- circular light
  local animation = AnimationFactory:newStaticSprite('light-blur')
  local ox, oy = animation:getOffset()
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    x,
    y,
    0,
    1,
    1,
    ox,
    oy
  )

  -- light beams
  local animation = AnimationFactory:newStaticSprite('legendary-item-drop-effect')
  local ox, oy = animation:getOffset()
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('add')
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    x,
    y,
    angle,
    1,
    1,
    ox,
    oy
  )
  love.graphics.setBlendMode(oBlendMode)
end

local function drawLegendaryItemEffectMinimap()
  local Color = require 'modules.color'
  love.graphics.setColor(Color.RARITY_LEGENDARY)
  local animation = AnimationFactory:newStaticSprite('legendary-item-drop-effect-minimap')
  local ox, oy = animation:getOffset()
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    0,
    0,
    0,
    1,
    1,
    ox,
    oy
  )
end

local function setDropPosition(parent, spriteWidth, spriteHeight)
  local Grid = require 'utils.grid'
  local config = require 'config.config'
  local gs = config.gridSize
  local DroppablePositionSearch = require 'components.loot-generator.droppable-position-search'
  local searchComplete = false
  local dropX, dropY = parent.x, parent.y
  local getDroppablePosition = DroppablePositionSearch(
    function(grid, x, y, dist)
      local cellValue = Grid.get(grid, x, y)
      local isDroppablePosition = (not searchComplete) and (cellValue and cellValue.walkable)
      if isDroppablePosition then
        local _, len = collisionWorlds.map:queryRect(x * gs, y * gs, spriteWidth, spriteHeight, dropItemCollisionFilter)
        searchComplete = len == 0
        if searchComplete then
          dropX = x * gs
          dropY = y * gs
        end
      end
      return isDroppablePosition
    end
  )
  local mapGrid = Component.get('MAIN_SCENE').mapGrid
  local iterCount = 0
  local Position = require 'utils.position'
  local Math = require 'utils.math'
  local gridX, gridY = Position.pixelsToGridUnits(parent.x, parent.y, gs)
  local prevC = Grid.get(mapGrid, gridX, gridY)
  local lootPositionsIterator = getDroppablePosition(
    mapGrid,
    gridX, gridY,
    true, 10
  )
  local iterating = true
  local positions
  while iterating do
    local nextPositions = lootPositionsIterator()
    positions = nextPositions or positions
    iterating = not not nextPositions
  end

  return dropX, dropY
end

function LootGenerator.init(self)
  self.state = self.state or {
    dropComplete = false
  }

  local parent = self
  assert(self.item ~= nil, 'item must be provided')

  local globalState = require 'main.global-state'
  local rootStore = globalState.gameState
  local screenX, screenY = self.x, self.y
  local item = self.item
  local isLegendary = itemConfig.rarity.LEGENDARY == item.rarity

  if isLegendary then
    local Sound = require 'components.sound'
    Sound.playEffect('legendary-item-drop.wav')
  end

  self:setParent(Component.get('MAIN_SCENE'))
  Component.addToGroup(self, Component.groups.gameWorld)
  Component.addToGroup(self, 'autoVisibility')

  local animation = AnimationFactory:new({
    itemSystem.getDefinition(item).sprite
  })

  local sx, sy, sw, sh = animation.sprite:getViewport()
  self.colObj = self:addCollisionObject(collisionGroups.floorItem, self.x, self.y, sw, sh)
    :addToWorld(collisionWorlds.map)

  local originalX, originalY = self.x, self.y
  local actualX, actualY = originalX, originalY
  if (not self.state.dropComplete) then
    self.state.dropComplete = true
    actualX, actualY = setDropPosition(self, sw, sh)
    self.x, self.y = actualX, actualY
    self.colObj:update(self.x, self.y)
  end

  Gui.create({
    isNew = true,
    group = itemGroup,
    -- debug = true,
    x = originalX,
    y = originalY,
    w = sw,
    h = sh,
    tweenClock = 0,
    inputContext = 'loot',
    selected = false,
    animationComplete = false,
    eventPriority = eventPriority,
    onCreate = function(self)
      self.clock = 0
      Component.addToGroup(self:getId(), 'clock', self)

      if parent.isNew then
        local tweenTarget = {
          tweenClock = 1
        }
        local dx = actualX - originalX
        self.initialX = self.x
        self.flyOutCurve = love.math.newBezierCurve(0, -5, dx/2, -10, dx, 0)
        parent.isNew = false
        local Math = require 'utils.math'
        local dist = Math.dist(self.x, self.y, actualX, actualY)
        local duration = math.max(0.001, dist * 0.01)
        self.tween = tween.new(duration, self, tweenTarget, tween.easing.backIn)
      end
    end,
    getMousePosition = itemMousePosition,
    onPointerMove = function(self)
      msgBus.send(msgBus.ITEM_HOVERED, self)
    end,
    pickup = function()
      local _, errorMsg = rootStore:addItemToInventory(item)
      if errorMsg then
        msgBus.send(msgBus.PLAYER_ACTION_ERROR, errorMsg)
        return false
      end
      parent:delete(true)
      return true
    end,
    onUpdate = function(self, dt)
      self.clock = self.clock + dt
      self.x = parent.x
      self.y = parent.y
      self.angle = self.angle + dt

      local minimap = Component.get('miniMap')
      if isLegendary and minimap then
        local Position = require 'utils.position'
        local config = require 'config.config'
        local gridX, gridY = Position.pixelsToGridUnits(self.x, self.y, config.gridSize)
        minimap:renderBlock(gridX, gridY, drawLegendaryItemEffectMinimap)
      end

      if (not parent.isInViewOfPlayer) then
        itemNamesTooltipLayer:delete(item)
        return
      end

      -- IMPORTANT: run any update logic before the pickup messages trigger, since those can
      -- cause the item to be deleted part-way through the update method, which will cause race conditions.
      itemNamesTooltipLayer:add(item, self.x, self.y + self.z, self)

      if self.tween then
        local complete = self.tween:update(dt)

        local dx, dz = self.flyOutCurve:evaluate(self.tweenClock)
        self.x, self.z = self.initialX + dx, dz

        if complete then
          self.tween = nil
        end
      end

      self.canInteract = msgBus.send('INTERACT_ENVIRONMENT_OBJECT', self)
    end,
    draw = function(self)
      if (not parent.isInViewOfPlayer) then
        return
      end

      -- draw item shadow
      love.graphics.setColor(0,0,0,.3)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y + (self.h * 1.25) + self.z,
        0,
        1, -0.5
      )

      local ox, oy = animation:getOffset()
      local centerX, centerY = self.x + ox, self.y + oy

      if isLegendary then
        drawLegendaryItemEffect(self, centerX, centerY, self.angle)
      end

      -- draw item
      love.graphics.setColor(1,1,1)

      if (self.canInteract) then
        require 'components.interactable-indicators'
        local uid = require 'utils.uid'
        Component.addToGroup(uid(), 'interactableIndicators', {
          x = self.x + self.w,
          y = self.y + (self.h / 2),
          rotation = -math.pi/2
        })
      end

      if self.hovered then
        love.graphics.setShader(shader)
        shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
        shader:send('outline_width', 1)
        shader:send('outline_color', outlineColor)
      end

      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y + self.z
      )

      Component.get('lightWorld'):addLight(centerX, centerY, 17, nil, 0.4)

      shader:send('outline_width', 0)
    end,

    onFinal = function(self)
      itemNamesTooltipLayer:delete(item)
    end,

    drawOrder = function(self)
      return 4
    end
  }):setParent(self)
end

function LootGenerator.update(self)
  self.colObj:update(self.x, self.y)
end

function LootGenerator.serialize(self)
  local Object = require 'utils.object-utils'
  return Object.immutableApply(self.initialProps, {
    x = self.x,
    y = self.y,
    isNew = self.isNew,
    state = self.state
  })
end

return Component.createFactory(LootGenerator)