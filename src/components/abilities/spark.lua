-- generates a spark effect

local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local Chance = require 'utils.chance'
local tween = require 'modules.tween'
local Color = require 'modules.color'

local Spark = {
  color = Color.WHITE,
  maxLifeTime = 0.35,
  opacity = 1
}

local animation = AnimationFactory:newStaticSprite('pixel-white-1x1')

function Spark.init(self)
  Component.addToGroup(self, 'all')
  Component.addToGroup(self, 'gameWorld')

  local psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 20)
  psystem:setQuads(animation.sprite)
  psystem:setOffset(animation:getOffset())
  psystem:setParticleLifetime(0.25, self.maxLifeTime)
  psystem:setEmissionRate(50)
  psystem:setSpeed(30)
  psystem:setRotation(0, math.pi/2)
  psystem:setSizes(1, 4)
  psystem:setSizeVariation(1)
  -- psystem:setLinearAcceleration(0, 0, 0, 0)
  psystem:setEmissionArea('ellipse', 10, 10, 0, false)
  local col = self.color
  psystem:setColors(
    col[1], col[2], col[3], 0.1,
    col[1], col[2], col[3], 1,
    1, 1, 1, 0.75,
    1, 1, 1, 0
  )
  self.psystem = psystem
  self.clock = 0

  local dt = 1/60
  -- setup particles in all random directions
  for i=1, 30 do
    self.psystem:update(dt)
    self.angle = self.angle + dt * 20
    self.psystem:setDirection(self.angle)
  end
  self.psystem:setEmissionRate(0)
  self.psystem:setDirection(-math.pi/4)
  self.lightColor = {1,1,1,1}

  local numFrames = self.maxLifeTime / dt
  self.opacityPerFrame = 1/numFrames
end

function Spark.update(self, dt)
  self.psystem:update(dt)

  self.clock = self.clock + dt
  self.opacity = self.opacity - self.opacityPerFrame
  if self.clock >= self.maxLifeTime then
    self:delete(true)
  end
  self.lightColor[4] = self.lightColor[4] * self.opacity
  Component.get('lightWorld'):addLight(self.x, self.y, 20, self.lightColor)
end

function Spark.draw(self)
  -- love.graphics.setColor(1,1,1,self.opacity)
  love.graphics.draw(self.psystem, self.x, self.y)
end

function Spark.drawOrder()
  local drawOrders = require 'modules.draw-orders'
  return drawOrders.SparkDraw
end

return Component.createFactory(Spark)