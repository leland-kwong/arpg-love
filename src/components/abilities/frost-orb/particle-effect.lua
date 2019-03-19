local AnimationFactory = require 'components.animation-factory'
local Component = require 'modules.component'
local camera = require 'components.camera'

return Component.createFactory({
  group = 'all',
  init = function(self)
    self.objects = {}
    local animation = AnimationFactory:newStaticSprite('cloud')
    self.psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 5000)
    self.psystem:setQuads(animation.sprite)
    self.psystem:setOffset(animation:getOffset())
    self.psystem:setColors(
      1,1,1,1,
      1,1,1,1,
      1,1,1,0
    )
    self.psystem:setDirection(math.pi/2)
    self.psystem:setSizes(1.4, 0.3)
    self.psystem:setSpeed(10, 10)
    self.psystem:setParticleLifetime(0.4)
    self.psystem:setEmissionRate(10)
    self.psystem:setEmissionArea('ellipse', 3, 3)
  end,
  update = function(self, dt)
    if self.parent.speed == 0 then
      self.psystem:setEmissionRate(0)
    end
    self.psystem:moveTo(self.x, self.y)
    self.psystem:update(dt)
  end,
  draw = function(self)
    local Color = require 'modules.color'
    love.graphics.setColor(Color.rgba255(188, 231, 255))
    love.graphics.draw(self.psystem)
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self.parent)
  end
})