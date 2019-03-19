local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

Component.create({
  id = 'InteractableIndicators',
  init = function(self)
    Component.addToGroup(self, 'all')
    self.clock = 0
  end,
  update = function(self, dt)
    self.clock = self.clock + (dt * 2)
  end,
  draw = function(self)
    local interactables = Component.groups.interactableIndicators.getAll()
    local offset = math.sin(self.clock)
    for _,interact in pairs(interactables) do
      love.graphics.setColor(1,1,1,1)
      local icon = AnimationFactory:newStaticSprite(interact.icon or 'gui-arrow-small')
      icon:draw(interact.x, interact.y + offset, interact.rotation or 0)
    end
    Component.clearGroup('interactableIndicators')
  end,
  drawOrder = function()
    local DrawOrders = require 'modules.draw-orders'
    return DrawOrders.InteractableIndicator
  end
})