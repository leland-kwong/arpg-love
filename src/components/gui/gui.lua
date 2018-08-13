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

local Gui = {
  -- props
  x = 0,
  y = 0,
  w = 0,
  h = 0,
  onClick = noop,
  onChange = noop,
  render = noop,
  type = 'button',
  checked = false,

  -- statics
  types = {
    BUTTON = 'button',
    TOGGLE = 'toggle'
  }
}

function Gui.init(self)
  msgBus.subscribe(function(msgType, msgValue)
    if self.buttonHovered and (msgBus.MOUSE_RELEASED == msgType) then
      self.onClick(self)
      if self.types.TOGGLE == self.type then
        self.checked = not self.checked
        self.onChange(self, self.checked)
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

  self.buttonHovered = false
  if len > 0 then
    for i=1, len do
      if items[i] == self.colObj then
        self.buttonHovered = true
      end
    end
  end
end

function Gui.draw(self)
  self.render(self)
end

return groups.gui.createFactory(Gui)