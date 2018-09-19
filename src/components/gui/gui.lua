local Component = require 'modules.component'
local font = require 'components.font'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local msgBus = require 'components.msg-bus'
local GuiNode = require 'components.gui.gui-node'
local collisionObject = require 'modules.collision'
local scale = require 'config.config'.scaleFactor
local noop = require 'utils.noop'
local f = require 'utils.functional'
local min, max = math.min, math.max

local COLLISION_CROSS = 'cross'
local mouseCollisionFilter = function()
  return COLLISION_CROSS
end

local function toggleTextInput(enabled)
  love.keyboard.setTextInput(enabled)
end
msgBus.on(msgBus.SET_TEXT_INPUT, toggleTextInput)
msgBus.send(msgBus.SET_TEXT_INPUT, false)

local guiType = {
  INTERACT = 'INTERACT', -- a stateless gui node used only for event listening
  BUTTON = 'BUTTON',
  TOGGLE = 'TOGGLE',
  TEXT_INPUT = 'TEXT_INPUT',
  LIST = 'LIST',
}

local Gui = {
  group = groups.gui,
  -- props
  x = 1,
  y = 1,
  w = 1,
  h = 1,
  onClick = noop,
  onChange = noop,
  onCreate = noop,
  onFocus = noop,
  onBlur = noop,
  onScroll = noop,
  onPointerDown = noop,
  onPointerEnter = noop,
  onPointerLeave = noop,
  onUpdate = noop,
  onPointerMove = noop,
  onFinal = noop,
  collision = true,
  collisionGroup = nil,
  getMousePosition = function()
    return love.mouse.getX() / scale, love.mouse.getY() / scale
  end,
  render = noop,
  type = guiType.INTERACT,

  -- for LIST type to define what axis is scrollable
  scrollableX = false,
  scrollableY = true,
  -- scroll limits. The value here represents how far you can scroll in each direction.
  scrollHeight = 0,
  scrollWidth = 0,
  scrollSpeed = 1,
  -- array of children for the LIST component
  children = {},

  checked = false,
  text = '',

  -- built-in state; these should not be externally mutated
  hovered = false,
  focused = false,
  scrollTop = 0,
  scrollLeft = 0,

  -- statics
  types = guiType
}

local function handleFocusChange(self, origFocused)
  local isFocusChange = origFocused ~= self.focused
  if isFocusChange then
    if self.focused then
      self.onFocus(self)
    else
      self.onBlur(self)
    end

    if guiType.TEXT_INPUT == self.type then
      msgBus.send(msgBus.SET_TEXT_INPUT, self.focused)
    end
  end
end

local function handleScroll(self, dx, dy)
  self.scrollLeft = self.scrollableX and min(0, self.scrollLeft - dx * self.scrollSpeed) or 0
  local maxScrollLeft = -self.scrollWidth
  local maxScrollLeftReached = self.scrollLeft <= maxScrollLeft
  if maxScrollLeftReached then
    self.scrollLeft = maxScrollLeft
  end

  self.scrollTop = self.scrollableY and min(0, self.scrollTop + dy * self.scrollSpeed) or 0
  local maxScrollTop = -self.scrollHeight
  local maxScrollTopReached = self.scrollTop <= maxScrollTop
  if maxScrollTopReached then
    self.scrollTop = maxScrollTop
  end

  self.scrollNode:setPosition(
    self.scrollNode.initialX + self.scrollLeft,
    self.scrollNode.initialY + self.scrollTop
  )
  self.onScroll(self)
end

function Gui.init(self)
  assert(guiType[self.type] ~= nil, 'invalid gui type'..tostring(self.type))

  if guiType.LIST == self.type then
    assert(self.h <= love.graphics.getHeight() / self.scale, 'scrollable list height should not be greater than window height')
    self.scrollNode = GuiNode.create({
      x = self.x,
      y = self.y,
      initialX = self.x,
      initialY = self.y
    }):setParent(self)
    f.forEach(self.children, function(child)
      child:setParent(self.scrollNode)
    end)
  end

  if guiType.TEXT_INPUT == self.type then
    assert(type(self.text) == 'string')
  end

  if guiType.TOGGLE == self.type then
    assert(type(self.checked) == 'boolean')
  end

  msgBus.on('*', function(msgValue, msgType)
    -- cleanup
    local shouldCleanup = self:isDeleted()
    if shouldCleanup then
      return msgBus.CLEANUP
    end

    if guiType.LIST == self.type and
      msgBus.MOUSE_WHEEL_MOVED == msgType and
      self.hovered
    then
      handleScroll(self, msgValue[1], msgValue[2])
    end

    if msgBus.MOUSE_PRESSED == msgType then
      local origFocused = self.focused
      self.focused = self.hovered

      handleFocusChange(self, origFocused)

      if self.hovered then
        local isRightClick = msgValue[3] == 2
        self.onClick(self, isRightClick)

        if guiType.TOGGLE == self.type then
          self.checked = not self.checked
          self.onChange(self, self.checked)
        end
      end
    end

    if self.hovered and love.mouse.isDown(1) then
        self.onPointerDown(self)
    end

    if self.focused and guiType.TEXT_INPUT == self.type then
      if msgBus.GUI_TEXT_INPUT == msgType then
        local txt = msgValue
        self.text = self.text..txt
        self.onChange(self)
      end

      -- handle backspace for text input
      if msgBus.KEY_PRESSED == msgType and msgValue.key == 'backspace' then
        self.text = string.sub(self.text, 1, #self.text - 1)
        self.onChange(self)
      end
    end

    return msgValue
  end)

  local posX, posY = self:getPosition()
  self.colObj = self:addCollisionObject(
    self.collisionGroup or self.type,
    posX, posY,
    self.w, self.h
  ):addToWorld(collisionWorlds.gui)

  self.onCreate(self)
end

local Lru = require 'utils.lru'
local mouseCollisionsCache = Lru.new(20)
local function indexByMouseCoord(x, y)
  local maxCols = love.graphics.getWidth()
  return (y * maxCols) + x
end

local function isDifferent(a, b)
  return a ~= b
end

function Gui.update(self, dt)
  local posX, posY = self:getPosition()
  self.colObj:update(posX, posY, self.w, self.h)

  local mx, my = self.getMousePosition()
  local cacheKey = indexByMouseCoord(mx, my)
  local items = mouseCollisionsCache:get(cacheKey)
  local hasChangedPosition = isDifferent(self.x, self.prevX) or isDifferent(self.y, self.prevY)
  local hasChanges = (not items) or hasChangedPosition
  if hasChanges then
    items = collisionWorlds.gui:queryPoint(mx, my, mouseCollisionFilter)
    mouseCollisionsCache:set(cacheKey, items)
  end

  self.hovered = false

  -- if the collided item is `self`, then we're hovered
  for i=1, #items do
    if items[i] == self.colObj then
      self.hovered = true
    end
  end

  local isPointerMove = self.hovered
  local hasPointerPositionChanged = posX ~= self.prevColPosX or posY ~= self.prevColPosY
  if isPointerMove then
    self.onPointerMove(self, posX, posY)
  end

  local hoverStateChanged = self.hovered ~= self.prevHovered
  if hoverStateChanged then
    if self.hovered then
      self.onPointerEnter(self)
    else
      self.onPointerLeave(self)
    end
  end

  self.onUpdate(self, dt)
  self.prevHovered = self.hovered
  self.prevColPosX = posX
  self.prevColPosY = posY
  self.prevX = self.x
  self.prevY = self.y
end

function Gui.draw(self)
  self.render(self)
end

function Gui.final(self)
  self.onFinal(self)
end

local drawOrderByType = {
  [guiType.LIST] = 2,
  default = 3
}
function Gui.drawOrder(self)
  return drawOrderByType[self.type] or drawOrderByType.default
end

return Component.createFactory(Gui)