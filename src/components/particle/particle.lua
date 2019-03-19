local Component = require 'modules.component'
local groups = require 'components.groups'
local Color = require 'modules.color'
local Tween = require 'modules.tween'
local scale = require 'config.config'.scaleFactor
local AnimationFactory = require 'components.animation-factory'

local ParticleTest = {
  group = groups.all,
  x = 0,
  y = 0,
  width = 8,
  duration = 0,
  opacity = 1,
  sprite = 'pixel-white-1x1'
}

function ParticleTest.init(self)
  self.initialX = self.x
  self.initialY = self.y

  local animation = AnimationFactory:newStaticSprite(self.sprite)

  local psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 500)
  psystem:setQuads(animation.sprite)
  psystem:setOffset(animation:getOffset())

  -- local psystem = love.graphics.newParticleSystem(image, 100)
  self.psystem = psystem
  psystem:setParticleLifetime(0.25, 0.35) -- Particles live at least 2s and at most 5s.
  psystem:setEmissionRate(100)
  psystem:setDirection(-math.pi / 2)
  psystem:setSpeed(90)
  psystem:setSizes(1, 2)
  psystem:setEmissionArea('ellipse', self.width, 0, 0, false)
  psystem:setSizeVariation(1)
	psystem:setLinearAcceleration(0, 0, 0, -50) -- Random movement in all directions.
  local col = Color.GOLDEN_PALE
  psystem:setColors(
    col[1], col[2], col[3], 0.1,
    col[1], col[2], col[3], 1,
    1, 1, 1, 0.75,
    1, 1, 1, 0
    -- , 255, 255, 255, 0 -- Fade to transparency.
  )

  self.tweenOpacity = Tween.new(self.duration, self, {opacity = 0}, Tween.easing.inExpo)
end

function ParticleTest.update(self, dt)
  self.psystem:update(dt)
  local complete = self.tweenOpacity:update(dt)
  if complete then
    self:delete()
  end
end

function ParticleTest.draw(self)
  love.graphics.setColor(1,1,1, self.opacity)
  love.graphics.push()
  local scale = 2
  love.graphics.scale(scale)
  self.psystem:setPosition((self.x - self.initialX) / scale, (self.y - self.initialY) / scale)
  -- Draw the particle system at the center of the game window.
  love.graphics.draw(self.psystem, self.initialX / scale, self.initialY / scale)
  love.graphics.pop()
end

function ParticleTest.drawOrder(self)
  return self.group:drawOrder(self) + 2
end

local Basic = Component.createFactory(ParticleTest)

return {
  Basic = Basic
}