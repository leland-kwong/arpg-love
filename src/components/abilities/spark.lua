-- generates a spark effect

local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local Chance = require 'utils.chance'
local tween = require 'modules.tween'
local Color = require 'modules.color'

local Spark = {
  color = Color.WHITE,
  maxLifeTime = 0.30,
  opacity = 1
}

local animation = AnimationFactory:newStaticSprite('pixel-white-1x1')

local psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 500)
psystem:setQuads(animation.sprite)
psystem:setOffset(animation:getOffset())
-- spread 360 degrees
-- psystem:setSpread(-math.pi * 2, math.pi * 2)
local speed = 10
psystem:setSpeed(0, speed)
local acceleration = 60
psystem:setLinearAcceleration(0, 0, 0, acceleration) -- move particles in all random directions
psystem:setSizes(2, 3)
psystem:setSizeVariation(1)
psystem:setEmissionArea('ellipse', 10, 10, 0, true)

-- particle system
local ParticleSystem = {}

function ParticleSystem.init(self)
  Component.addToGroup(self, 'all')
end

function ParticleSystem.update(self, dt)
  psystem:update(dt)
end

function ParticleSystem.draw(self)
  love.graphics.draw(psystem, 0, 0)
end

function ParticleSystem.drawOrder()
  local drawOrders = require 'modules.draw-orders'
  return drawOrders.SparkDraw
end

Component.create(ParticleSystem)

function Spark.init(self)
  Component.addToGroup(self, 'all')
  Component.addToGroup(self, 'gameWorld')

  psystem:setParticleLifetime(0.30, self.maxLifeTime)
  local col = self.color
  psystem:setColors(
    1, 1, 1, 1,
    col[1], col[2], col[3], 0.5,
    col[1], col[2], col[3], 0
  )
  psystem:setPosition(self.x, self.y)
  psystem:emit(20)

  self.clock = 0
end

function Spark.update(self, dt)
  self.clock = self.clock + dt
  local percentLifeTime = self.clock / self.maxLifeTime
  self.opacity = self.opacity - (self.opacity * percentLifeTime)
  if self.clock >= self.maxLifeTime then
    self:delete(true)
  end
  Component.get('lightWorld'):addLight(self.x, self.y, 20, nil, self.opacity)
end

return Component.createFactory(Spark)