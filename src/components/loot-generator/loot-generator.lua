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

local itemGroup = groups.all
local tooltipCollisionWorld = bump.newWorld(16)
local function itemMousePosition()
  return camera:getMousePosition()
end

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = AnimationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)
shader:send('outline_color', outlineColor)

local DRAW_ORDER_BACKGROUND = 3
local DRAW_ORDER_TEXT = DRAW_ORDER_BACKGROUND + 1
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
        x = tooltip.x,
        y = tooltip.y,
        w = ttWidth,
        h = ttHeight,
        getMousePosition = itemMousePosition,
        onUpdate = function(self)
          tooltip.hovered = self.hovered
        end,
        onClick = function()
          msgBus.send(msgBus.ITEM_PICKUP, itemParent)
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

local LootGenerator = {
  group = itemGroup,
  rootStore = CreateStore,
  class = collisionGroups.floorItem,
  -- item to generate
  item = nil
}

local COLLISION_FLOOR_ITEM_TYPE = 'floorItem'
local function collisionFilter(item, other)
  if other.group == COLLISION_FLOOR_ITEM_TYPE or collisionGroups.matches(other.group, collisionGroups.obstacle) then
    return 'slide'
  end
  return false
end

-- parabola that goes up and back down
local curve = love.math.newBezierCurve(0, 0, 10, -10, 0, 0)
local function flyoutEasing(t, b, c, d)
  return c * curve:evaluate(t/d) + b
end

function LootGenerator.init(self)
  assert(self.item ~= nil, 'item must be provided')

  local parent = self
  local rootStore = msgBus.send(msgBus.GAME_STATE_GET)
  local screenX, screenY = self.x, self.y
  local item = self.item

  local animation = AnimationFactory:new({
    itemSystem.getDefinition(item).sprite
  })

  local sx, sy, sw, sh = animation.sprite:getViewport()
  local colObj = self:addCollisionObject(COLLISION_FLOOR_ITEM_TYPE, self.x, self.y, sw, sh)
    :addToWorld(collisionWorlds.map)

  Gui.create({
    group = itemGroup,
    -- debug = true,
    x = self.x,
    y = self.y,
    w = sw,
    h = sh,
    selected = false,
    animationComplete = false,
    onCreate = function(self)
      local direction = math.random(0, 1) == 1 and 1 or -1
      local xOffset = math.random(10, 20)
      local yOffset = -10 -- cause item to fly upwards
      local endStateX = {
        x = self.x + direction * xOffset
      }
      local endStateY = {
        y = self.y + yOffset
      }
      -- check collision of position to make sure its at a droppable position
      local actualX, actualY, cols, len = colObj:move(endStateX.x, endStateY.y, collisionFilter)
      if len > 0 then
        parent.x = actualX
        parent.y = actualY
        endStateX.x = actualX
        -- update initial position to new initial position
        self.y = actualY - yOffset
        endStateY.y = actualY
      end

      -- y-axis animation
      self.tween = tween.new(0.5, self, endStateY, flyoutEasing)
      -- x-axis animation
      self.tween2 = tween.new(0.5, self, endStateX)
    end,
    getMousePosition = itemMousePosition,
    onPointerEnter = function()
      msgBus.send(msgBus.ITEM_HOVERED, true)
    end,
    onPointerLeave = function()
      msgBus.send(msgBus.ITEM_HOVERED, false)
    end,
    pickup = function()
      if parent.pickupPending then
        return
      end
      rootStore:addItemToInventory(item)
      parent:delete(true)
    end,
    onClick = function(self)
      self.selected = true
      msgBus.send(msgBus.ITEM_PICKUP, self)
    end,
    onUpdate = function(self, dt)
      local boundsThreshold = 32
      self.isOutOfBounds = self:checkOutOfBounds(boundsThreshold)
      if self.isOutOfBounds then
        itemNamesTooltipLayer:delete(item)
        return
      end

      -- IMPORTANT: run any update logic before the pickup messages trigger, since those can
      -- cause the item to be deleted part-way through the update method, which will cause race conditions.
      itemNamesTooltipLayer:add(item, self.x, self.y, self)

      if not self.animationComplete then
        local complete = self.tween:update(dt)
        self.tween2:update(dt)
        self.animationComplete = complete
      end
    end,
    draw = function(self)
      if self.isOutOfBounds then
        return
      end
      -- draw item shadow
      love.graphics.setColor(0,0,0,.3)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y + (self.h * 1.25),
        0,
        1, -0.5
      )

      if self.hovered then
        love.graphics.setShader(shader)
      end

      -- draw item
      love.graphics.setColor(1,1,1)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y
      )

      if self.hovered then
        love.graphics.setShader()
      end
    end,

    onFinal = function(self)
      itemNamesTooltipLayer:delete(item)
    end
  }):setParent(self)
end

function LootGenerator.serialize(self)
  local state = {}
  for k,v in pairs(self) do
    state[k] = v
  end
  return state
end

return Component.createFactory(LootGenerator)