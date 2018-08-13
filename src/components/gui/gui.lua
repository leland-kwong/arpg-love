local font = require 'components.font'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local msgBus = require 'components.msg-bus'
local collisionObject = require 'modules.collision'
local scale = require 'config'.scaleFactor
local noop = require 'utils.noop'

local COLLISION_CROSS = 'cross'
local mouseCollisionFilter = function()
  return COLLISION_CROSS
end

msgBus.subscribe(function(msgType, enabled)
  if msgBus.SET_TEXT_INPUT == msgType then
    love.keyboard.setTextInput(enabled)
  end
end)
msgBus.send(msgBus.SET_TEXT_INPUT, false)

local guiType = {
  BUTTON = 'BUTTON',
  TOGGLE = 'TOGGLE',
  TEXT_INPUT = 'TEXT_INPUT'
}

local Gui = {
  -- props
  x = 0,
  y = 0,
  w = 0,
  h = 0,
  onClick = noop,
  onChange = noop,
  onFocus = noop,
  onBlur = noop,
  render = noop,
  type = 'button',
  checked = false,
  text = '',

  -- built-in state; these should not be externally mutated
  hovered = false,
  focused = false,

  -- statics
  types = guiType
}

local function handleFocusChange(origFocused, self)
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

function Gui.init(self)
  if guiType.TEXT_INPUT == self.type then
    assert(type(self.text) == 'string')
  end

  if guiType.TOGGLE == self.type then
    assert(type(self.checked) == 'boolean')
  end

  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.GUI_NODE_CLEANUP == msgType and msgValue == self:getId() then
      return msgBus.CLEANUP
    end

    if msgBus.MOUSE_RELEASED == msgType then
      local origFocused = self.focused
      self.focused = self.hovered

      handleFocusChange(origFocused, self)

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
      end

      -- handle backspace for text input
      if msgBus.KEY_PRESSED == msgType and msgValue.key == 'backspace' then
        self.text = string.sub(self.text, 1, #self.text - 1)
      end
    end
  end)

  self.colObj = collisionObject:new(
    'button',
    self.x, self.y,
    self.w, self.h
  ):addToWorld(collisionWorlds.gui)
end

function Gui.update(self)
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
end

return groups.gui.createFactory(Gui)