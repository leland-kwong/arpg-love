local Component = require 'modules.component'
local AF = require 'components.animation-factory'

local ImpactAnimation = {}

function ImpactAnimation.init(self)
  Component.addToGroup(self, 'all')

  self.animation = AF:new({
    'impact-animation-0',
    'impact-animation-1',
    'impact-animation-2',
    'impact-animation-3'
  }):setDuration(0.3)
end

function ImpactAnimation.update(self, dt)
  if self.animation:isLastFrame() then
    self:delete(true)
    return
  end
  self.animation:update(dt)
end

function ImpactAnimation.draw(self)
  local ox, oy = self.animation:getOffset()
  love.graphics.setColor(1,1,1)
  love.graphics.draw(
    AF.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    0,
    1, 1,
    ox, oy
  )
end

function ImpactAnimation.drawOrder(self)
  return Component.groups.all:drawOrder(self) + 20
end

return Component.createFactory(ImpactAnimation)