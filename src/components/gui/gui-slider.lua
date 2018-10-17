local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local noop = require 'utils.noop'

return Component.createFactory({
  value = 0,
  width = 100,
  min = 0, -- minimum slider value
  max = 100, -- maximum slider value
  increment = 1, -- slider value increments

  -- internal props
  isDragStart = false,
  beforeDragValue = 0,
  onChange = noop,

  init = function(self)
    Component.addToGroup(self, 'gui')
    local knobCollisionSize = 8
    local knobOffsetX = knobCollisionSize/2
    self.railHeight = 4
    self.knob = Gui.create({
      x = self.x - knobOffsetX,
      y = self.y - knobCollisionSize/2 + self.railHeight/2,
      w = knobCollisionSize,
      h = knobCollisionSize,
      type = Gui.types.INTERACT
    }):setParent(self)
    self.listeners = {
      msgBus.on(msgBus.MOUSE_PRESSED, function(ev)
        local x, y, button = unpack(ev)
        if self.knob.hovered and (button == 1) then
          self.isDragStart = true
        end
      end),
      msgBus.on(msgBus.MOUSE_DRAG_START, function()
        self.beforeDragValue = self.value
      end),
      msgBus.on(msgBus.MOUSE_DRAG, function(ev)
        local clamp = require 'utils.math'.clamp
        if self.knob.hovered or self.isDragStart then
          self.value = clamp(self.beforeDragValue + ev.dx/2, 0, self.width)
          self.isDragStart = true
          -- local min, max = self.x - knobOffsetX, self.x + 100 - knobOffsetX
          local nextPos = self.x - knobOffsetX + self.value
          self.knob.x = nextPos
        end
      end),
      msgBus.on(msgBus.MOUSE_RELEASED, function()
        self.isDragStart = false
      end)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})