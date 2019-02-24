local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local scale = require 'config.config'.scaleFactor
local groups = require 'components.groups'
local ParticleFx = dynamicRequire 'components.particle.particle'
local tick = require'utils.tick'
local Color = require 'modules.color'
local Tween = require 'modules.tween'
local scale = require 'config.config'.scaleFactor
local AnimationFactory = require 'components.animation-factory'
local FrostOrb = dynamicRequire 'components.abilities.frost-orb'
local msgBus = require 'components.msg-bus'

local ParticleFx = {
  group = 'all',
  x = 0,
  y = 0,
  width = 4,
  duration = 0,
  opacity = 1,
  sprite = 'pixel-white-1x1'
}

function ParticleFx.init(self)
  local animation = AnimationFactory:newStaticSprite(self.sprite)
  local psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 1000)
  self.psystem = psystem

  local p = self.psystem
  p:setQuads(animation.sprite)
  p:setOffset(animation:getOffset())
  p:setParticleLifetime(0.3, 0.4)
  p:setEmissionRate(0)
  p:setSpeed(0)
  p:setRotation(0, math.pi)
  p:setSizes(1.3, 0.6, 0)
  p:setEmissionArea('ellipse', self.width, 0, 0, false)
  p:setSizeVariation(1)
	p:setLinearAcceleration(0, 0, 0, 0) -- Random movement in all directions.
  local col = Color.SKY_BLUE
  p:setColors(
    -- col[1], col[2], col[3], 0,
    -- col[1], col[2], col[3], 0.5,
    1,1,1,1,
    1, 1, 1, 0
  )

  self.tweenOpacity = Tween.new(self.duration, self, {opacity = 0}, Tween.easing.inExpo)
end

function ParticleFx.update(self, dt)
  self.psystem:update(dt)

  local complete = self.tweenOpacity:update(dt)
  if complete then
    self:delete()
  end
  for _,orb in pairs(Component.groups.frostOrbs.getAll()) do
    if not orb.expiring then
      self.psystem:setPosition(orb.x, orb.y)
      self.psystem:emit(1)
    end
  end
end

function ParticleFx.draw(self)
  love.graphics.setColor(1,1,1, self.opacity)
  love.graphics.draw(self.psystem, 0, 0)
end

function ParticleFx.drawOrder(self)
  return 2
end

ParticleFx = Component.createFactory(ParticleFx)

Component.create({
  id = 'ParticleTest',
  group = 'all',
  init = function(self)
    local x, y = 0, 0
    self.particleFx = ParticleFx.create({
      x = x,
      y = y + 6,
      duration = 9999,
      sprite = 'cloud'
    }):setParent(self)

    self.listeners = {
      msgBus.on('MOUSE_PRESSED', function()
        local camera = require 'components.camera'
        local mx, my = camera:getMousePosition()

        local orb = FrostOrb.create({
          x = 0,
          y = 0,
          speed = 100,
          x2 = mx,
          y2 = my,
          drawOrder = function()
            return 4
          end
        })
        Component.addToGroup(orb, 'frostOrbs')
      end)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})