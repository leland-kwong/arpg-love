local Component = require 'modules.component'
local font = require 'components.font'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local msgBus = require 'components.msg-bus'
local collisionObject = require 'modules.collision'
local scale = require 'config'.scaleFactor
local noop = require 'utils.noop'
local f = require 'utils.functional'
local min, max = math.min, math.max

local COLLISION_CROSS = 'cross'
local mouseCollisionFilter = function()
  return COLLISION_CROSS
end

local function toggleTextInput(msgType, enabled)
  if msgBus.SET_TEXT_INPUT == msgType then
    love.keyboard.setTextInput(enabled)
  end
end
msgBus.subscribe(toggleTextInput)
msgBus.send(msgBus.SET_TEXT_INPUT, false)

--[[
  A generic node with no built-in functionality.
  Currently used internally as a node for the parenting of childNodes to the LIST
]]
local GuiNode = Component.createFactory({
  group = groups.gui
})

local guiType = {
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
  onFocus = noop,
  onBlur = noop,
  onScroll = noop,
  render = noop,
  type = 'button',

  -- for LIST type to define what axis is scrollable
  scrollableX = false,
  scrollableY = true,
  -- scroll limits. The value here represents how far you can scroll in each direction.
  scrollHeight = 0,
  scrollWidth = 0,
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
  self.scrollLeft = self.scrollableX and min(0, self.scrollLeft - dx) or 0
  local maxScrollLeft = -self.scrollWidth
  local maxScrollLeftReached = self.scrollLeft <= maxScrollLeft
  if maxScrollLeftReached then
    self.scrollLeft = maxScrollLeft
  end

  self.scrollTop = self.scrollableY and min(0, self.scrollTop + dy) or 0
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
    })
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

  msgBus.subscribe(function(msgType, msgValue)
    -- cleanup
    if msgBus.GUI_NODE_CLEANUP == msgType and msgValue == self:getId() then
      return msgBus.CLEANUP
    end

    if guiType.LIST == self.type and
      msgBus.MOUSE_WHEEL_MOVED == msgType and
      self.hovered
    then
      handleScroll(self, msgValue[1], msgValue[2])
    end

    if msgBus.MOUSE_RELEASED == msgType then
      local origFocused = self.focused
      self.focused = self.hovered

      handleFocusChange(self, origFocused)

      if self.hovered then
        self.onClick(self)

        if guiType.TOGGLE == self.type then
          self.checked = not self.checked
          self.onChange(self, self.checked)
        end
      end
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
  end)

  local posX, posY = self:getPosition()
  self.colObj = collisionObject:new(
    'button',
    posX, posY,
    self.w, self.h
  ):addToWorld(collisionWorlds.gui)
end

function Gui.update(self)
  local posX, posY = self:getPosition()
  self.colObj:update(posX, posY, self.w, self.h)

  local items, len = collisionWorlds.gui:queryPoint(
    love.mouse.getX() / scale, love.mouse.getY() / scale, mouseCollisionFilter
  )

  self.hovered = false

  -- if the collided item is `self`, then we're hovered
  if len > 0 then
    for i=1, len do
      if items[i] == self.colObj then
        self.hovered = true
      end
    end
  end
end

function Gui.draw(self)
  self.render(self)
end

function Gui.final(self)
  msgBus.send(msgBus.GUI_NODE_CLEANUP, self:getId())

  if guiType.LIST == self.type then
    f.forEach(self.children, function(child)
      -- unset the parent
      child:setParent()
    end)
  end
end

local drawOrderByType = {
  [guiType.LIST] = 1,
  default = 2
}
function Gui.drawOrder(self)
  return drawOrderByType[self.type] or drawOrderByType.default
end

return Component.createFactory(Gui)