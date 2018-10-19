local Component = require 'modules.component'
local loadImage = require 'modules.load-image'
local Color = require 'modules.color'
local config = require 'config.config'
local Console = require 'modules.console.console'

local color = Color.GOLDEN_PALE

local StarField = {
  speed = {5, 50},
  sizes = {1, 2, 3},
  x = 0,
  y = 0,
  direction = 0,
  emissionRate = 500,
  updateRate = 1, -- [INT] Updates the system every {x} frames. Larger values means less frequent updates
  particleLifeTime = {3, 10},
  drawColor = {1,1,1,1},
  particleBaseColor = Color.GOLDEN_PALE,
  width = 0,
  height = 0,
  frameCount = 0,
  preWarm = 120, -- number of frames to pre warm
}

function StarField.init(self)
  Component.addToGroup(self, 'firstLayer')
  self.width = love.graphics.getWidth() / config.scale
  self.height = love.graphics.getHeight() / config.scale

  local color = self.particleBaseColor
  self.particleColors = {
    {color[1], color[2], color[3], 0.1},
    {color[1], color[2], color[3], 1},
    {1, 1, 1, 0.75},
    {1, 1, 1, 0}
  }

  local imageObj = loadImage('built/images/pixel-1x1-white.png')
  self.psystem = love.graphics.newParticleSystem(imageObj, self.emissionRate)
  local psystem = self.psystem
  psystem:setParticleLifetime(unpack(self.particleLifeTime))
  psystem:setEmissionRate(self.emissionRate)
  psystem:setDirection(self.direction)
  psystem:setSpeed(unpack(self.speed))
  psystem:setSizes(unpack(self.sizes))
  psystem:setSizeVariation(1)
  psystem:setLinearAcceleration(0, 0, 0, 0) -- Random movement in all directions.
  psystem:setColors(unpack(self.particleColors))
  self.psystem:setEmissionArea(
    'ellipse',
    self.width,
    self.height,
    0,
    false
  )

  -- pre-warm the starfield
  for i=1, self.preWarm do
    psystem:update(0.16)
  end
end

function StarField.update(self, dt)
  self.frameCount = self.frameCount + 1
  if (self.frameCount % self.updateRate) == 0 then
    self.psystem:update(dt)
  end
end

function StarField.draw(self)
  love.graphics.setColor(self.drawColor)
  love.graphics.draw(self.psystem, self.x, self.y)
end

function StarField.drawOrder()
  return 1
end

return Component.createFactory(StarField)