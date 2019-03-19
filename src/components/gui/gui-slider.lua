local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local noop = require 'utils.noop'

local function getKnobX(self)
  local knobOffsetX = self.knobSize/2
  return (self.x - knobOffsetX + self.value)
end

return Component.createFactory({
  value = 0, -- NOTE: values should be out of 100. This makes it simple since values must be in percentage
  width = 100,
  knobSize = 10,

  -- internal props
  isDragStart = false,
  beforeDragValue = 0,
  onChange = noop,

  -- returns the value relative to the component's rail size so that it is always out of 100
  getCalculatedValue = function(self)
    local scale = 100/self.width
    return self.value * scale
  end,

  setCalculatedValue = function(self, value)
    local scale = self.width/100
    self.value = value * scale
    self.knob.x = getKnobX(self)
    return self
  end,

  init = function(self)
    Component.addToGroup(self, 'gui')

    self.railHeight = 4
    self.knob = Gui.create({
      inputContext = self.inputContext,
      x = getKnobX(self),
      y = self.y - self.knobSize/2 + self.railHeight/2,
      w = self.knobSize,
      h = self.knobSize,
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
          self.value = clamp(self.beforeDragValue + ev.dx/self.scale, 0, self.width)
          self.isDragStart = true
          self.knob.x = getKnobX(self)
        end
      end),
      msgBus.on(msgBus.MOUSE_RELEASED, function()
        local wasDragging = self.isDragStart
        if wasDragging then
          self:onChange()
        end
        self.isDragStart = false
      end)
    }
  end,
  update = function(self)
    self.scale = self.knob.scale
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})