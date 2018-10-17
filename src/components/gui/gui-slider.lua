local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local noop = require 'utils.noop'

return Component.createFactory({
  value = 0,
  width = 100,
  knobSize = 10,
  resolutionScale = 2,

  -- internal props
  isDragStart = false,
  beforeDragValue = 0,
  onChange = noop,

  -- returns the value relative to the component's rail size so that it is always out of 100
  getCalculatedValue = function(self)
    local scale = 100 / self.width
    return self.value * scale
  end,

  init = function(self)
    self.rangeTotal = self.min + self.max
    self.actualValue = self:getCalculatedValue()

    Component.addToGroup(self, 'gui')
    local knobCollisionSize = self.knobSize
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
          self.value = clamp(self.beforeDragValue + ev.dx/self.resolutionScale, 0, self.width)
          self.isDragStart = true
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