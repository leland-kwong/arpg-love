local Component = require 'modules.component'
local groups = require 'components.groups'
local Color = require 'modules.color'
local Tween = require 'modules.tween'
local scale = require 'config.config'.scaleFactor
local AnimationFactory = require 'components.animation-factory'

local image = love.graphics.newImage('built/images/pixel-1x1-white.png')

local GroundFlame = {
  group = groups.firstLayer,
  x = 0,
  y = 0,
  width = 8,
  height = 8,
  duration = 0,
  opacity = 1,
}

local function makeSystem(color, direction, width, height)
  local psystem = love.graphics.newParticleSystem(image, 100)
  psystem:setParticleLifetime(0.2, 0.6) -- Particles live at least 2s and at most 5s.
  psystem:setEmissionRate(100)
  psystem:setDirection(direction)
  psystem:setSpeed(10)
  psystem:setSizes(2, 7)
  psystem:setEmissionArea('ellipse', width, height, 0, false)
  psystem:setSizeVariation(1)
	psystem:setLinearAcceleration(0, 0, 0, -10) -- Random movement in all directions.
  local col = color
  psystem:setColors(
    1,1,0,1,
    col[1], col[2], col[3], 0,
    col[1], col[2], col[3], 1,
    0.5, 0.5, 0.5, 0
  )
  return psystem
end

function GroundFlame.init(self)
  self.initialX = self.x
  self.initialY = self.y
  self.psystem1 = makeSystem(
    {Color.rgba255(240,167,17,1)},
    -math.pi / 2,
    self.width, self.height
  )
  self.tweenOpacity = Tween.new(self.duration, self, {opacity = 0}, Tween.easing.inExpo)
end

function GroundFlame.update(self, dt)
  self.psystem1:update(dt)
  local complete = self.tweenOpacity:update(dt)
  if complete then
    self:delete()
  end
end

local function drawTile(x, y)
  local tile = AnimationFactory:newStaticSprite('floor-1')
  love.graphics.draw(
    AnimationFactory.atlas,
    tile.sprite,
    x,
    y
  )
end

function GroundFlame.draw(self)
  -- render 'hot' looking tiles
  love.graphics.setBlendMode('add')
  local gridSize = self.gridSize
  love.graphics.setColor(1,0.5,0,1 * self.opacity)
  drawTile(self.x - gridSize, self.y)
  drawTile(self.x - gridSize, self.y - gridSize)
  drawTile(self.x, self.y - gridSize)
  drawTile(self.x, self.y)
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1,1,1, self.opacity)
  love.graphics.draw(self.psystem1, self.x, self.y)
end

return Component.createFactory(GroundFlame)