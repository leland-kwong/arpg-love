local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local itemDefs = require 'components.item-inventory.items.item-definitions'
local itemConfig = require 'components.item-inventory.items.config'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local camera = require 'components.camera'
local CreateStore = require 'components.state.state'
local msgBus = require 'components.msg-bus'
local tick = require 'utils.tick'
local tween = require 'modules.tween'
local bump = require 'modules.bump'

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

local DRAW_ORDER_BACKGROUND = 200
local DRAW_ORDER_TEXT = DRAW_ORDER_BACKGROUND + 1
local itemNameTextLayer = GuiText.create({
  group = groups.all,
  font = require 'components.font'.primary.font,
  drawOrder = function(self)
    return DRAW_ORDER_TEXT
  end
})

local itemNamesTooltipLayer = Gui.create({
  group = groups.all,
  tooltipPadding = 4,
  drawOrder = function(self)
    return DRAW_ORDER_BACKGROUND
  end,
  onCreate = function(self)
    self.cache = {}
  end,
  set = function(self, item, x, y, itemParent)
    local hasChangedPosition = x ~= self.lastX or y ~= self.lastY
    self.lastX = x
    self.lastY = y
    if not hasChangedPosition then
      return
    end

    y = y - 16 -- start above the item
    local isNew = self.cache[item] == nil
    self.cache[item] = self.cache[item] or {
      x = x,
      y = y,
      hovered = false,
      itemParent = itemParent
    }
    local tooltip = self.cache[item]
    tooltip.x = x
    tooltip.y = y

    if isNew then
      local def = itemDefs.getDefinition(item)
      local bgWidth, bgHeight = GuiText.getTextSize(def.title, itemNameTextLayer.font)
      local ttWidth, ttHeight = bgWidth + self.tooltipPadding,
        bgHeight + self.tooltipPadding
      tooltipCollisionWorld:add(
        tooltip,
        tooltip.x,
        tooltip.y,
        ttWidth,
        ttHeight
      )

      tooltip.gui = Gui.create({
        group = groups.all,
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
    tooltipCollisionWorld:remove(tooltip)
    tooltip.gui:delete()
  end,
  onUpdate = function(self)
    local floor = math.floor
    for item, tooltip in pairs(self.cache) do
      local actualX, actualY, cols, len = tooltipCollisionWorld:move(tooltip, tooltip.x, tooltip.y)
      tooltip.x = floor(actualX)
      tooltip.y = floor(actualY)
      tooltip.gui:setPosition(tooltip.x, tooltip.y)
      tooltip.hovered = tooltip.hovered or tooltip.itemParent.hovered
    end
  end,
  draw = function(self)
    for item, tooltip in pairs(self.cache) do
      local def = itemDefs.getDefinition(item)
      local itemName = def.title
      local textColor = itemConfig.rarityColor[def.rarity]
      local bgWidth, bgHeight = GuiText.getTextSize(itemName, itemNameTextLayer.font)
      local padding = self.tooltipPadding

      love.graphics.setColor(0,0,0,0.8)
      love.graphics.rectangle(
        'fill',
        tooltip.x,
        tooltip.y,
        bgWidth + padding,
        bgHeight + padding
      )
      itemNameTextLayer:add(itemName, textColor, tooltip.x + padding/2, tooltip.y + padding/2 + 1)

      if tooltip.hovered then
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle(
          'line',
          tooltip.x,
          tooltip.y,
          bgWidth + padding,
          bgHeight + padding
        )
      end
    end
  end
})

local LootGenerator = {
  group = groups.all,
  rootStore = CreateStore,
  -- item to generate
  item = nil
}

local COLLISION_FLOOR_ITEM_TYPE = 'floorItem'
local function collisionFilter(item, other)
  if other.group == COLLISION_FLOOR_ITEM_TYPE or other.group == 'obstacle' then
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

  local _self = self
  local rootStore = self.rootStore
  local screenX, screenY = self.x, self.y
  local item = self.item

  local animation = AnimationFactory:new({
    itemDefs.getDefinition(item).sprite
  })

  local sx, sy, sw, sh = animation.sprite:getViewport()

  local colObj = self:addCollisionObject(COLLISION_FLOOR_ITEM_TYPE, self.x, self.y, sw, sh)
    :addToWorld(collisionWorlds.map)

  Gui.create({
    group = groups.all,
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
        endStateX.x = actualX
        -- update initial position to new initial position
        self.y = actualY
        endStateY.y = actualY + yOffset
      end

      self.tween = tween.new(0.5, self, endStateY, flyoutEasing)
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
      if _self.pickupPending then
        return
      end
      rootStore:addItemToInventory(item)
      _self:delete(true)
      -- --[[
      --   Add a slight delay for ITEM_PICKUP_SUCCESS since we disable the player's click events
      --   after pickup to prevent attack on pickup.
      -- ]]
      _self.pickupPending = tick.delay(function()
        msgBus.send(msgBus.ITEM_PICKUP_SUCCESS)
      end, 0.2)
    end,
    onClick = function(self)
      self.selected = true
      msgBus.send(msgBus.ITEM_PICKUP, self)
    end,
    onUpdate = function(self, dt)
      -- IMPORTANT: run any update logic before the pickup messages trigger, since those can
      -- cause the item to be deleted part-way through the update method, which will cause race conditions.
      itemNamesTooltipLayer:set(item, self.x, self.y, self)

      if not self.animationComplete then
        local complete = self.tween:update(dt)
        self.tween2:update(dt)
        self.animationComplete = complete
      end
    end,
    draw = function(self)
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

return Component.createFactory(LootGenerator)