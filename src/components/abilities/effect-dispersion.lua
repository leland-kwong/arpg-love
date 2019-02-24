local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

local impactAnimation = AnimationFactory:newStaticSprite('nova')

local Color = require 'modules.color'
local ImpactDispersion = {
  radius = 10,
  duration = 10, -- number of frames
  scale = {
    x = 1,
    y = 1
  },
  color = Color.WHITE
}

function ImpactDispersion.init(self)
  Component.addToGroup(self, 'all')
  Component.addToGroup(self, 'gameWorld')
  self.maxFrames = 100
  self.maxRadius = self.radius + self.maxFrames
  self.frameCount = 0
end

function ImpactDispersion.update(self)
  local displayRadius = math.min(self.maxRadius, self.radius + self.frameCount)
  self.displayRadius = displayRadius
  self.frameCount = self.frameCount + (60 / self.duration)

  local complete = self.frameCount >= self.maxFrames
  if complete then
    self:delete(true)
  end
end

function ImpactDispersion.draw(self)
  local opacity = math.min((self.maxFrames - self.frameCount) / self.maxFrames, 1)
  love.graphics.setColor(Color.multiplyAlpha(self.color, opacity))
  local imageWidth = impactAnimation:getSourceSize()
  local renderSize = self.displayRadius / imageWidth
  love.graphics.draw(
    AnimationFactory.atlas,
    impactAnimation.sprite,
    (self.x - self.displayRadius/2) + ((1 - self.scale.x) * self.displayRadius/2),
    (self.y - self.displayRadius/2) + ((1 - self.scale.y) * self.displayRadius/2),
    0,
    renderSize * self.scale.x,
    renderSize * self.scale.y
  )
end

function ImpactDispersion.drawOrder()
  return 3
end

return Component.createFactory(ImpactDispersion)