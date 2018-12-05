local function length(x1, y1, x2, y2)
  local a = x2 - x1
	local b = y2 - y1
	return math.sqrt(a*a + b*b)
end

local frozenShatterEffect = function(particleImage, particleImageQuad)
  return function(params)
    local startX, startY, startZ, speed, numParticlesMin, numParticlesMax, sizeMin, sizeMax, lifeTime = unpack(params)
    math.randomseed(os.clock())
    speed = speed or 1
    lifeTime = lifeTime or 0.5
    numParticlesMin = numParticlesMin or 5
    numParticlesMax = numParticlesMax or 5

    local numParticles = math.random(numParticlesMin, numParticlesMax)
    local initialX, initialY = 0, -startZ
    local function makeCurve(xDirection, yOffset, magnitudeX, magnitudeY)
      local peakY, endY = initialY - (5 * magnitudeY or 1) + yOffset, 0 + yOffset
      local peakX = xDirection * magnitudeX
      local endX = peakX + xDirection * magnitudeX
      local curve = love.math.newBezierCurve({
        initialX, initialY, initialX + peakX, peakY, endX, endY
      })
      curve:translate(startX, startY)
      return curve
    end
    local function randomDirection()
      return math.random(0, 1) == 1 and 1 or -1
    end
    local particles = {}
    for i=1, numParticles do
      local curve = makeCurve(
        randomDirection(),
        -math.random(0, 5),
        -math.random(0, 5),
        math.random(0, 2)
      )
      local endX, endY = curve:evaluate(1)
      local dist = length(initialX, initialY, startX - endX, startY - endY)
      table.insert(
        particles,
        {
          curve = curve,
          endPt = {endX, endY},
          size = math.random(sizeMin, sizeMax),
          dist = dist,
          clock = 0,
          lifeTime = 0
        }
      )
    end
    table.sort(particles, function(a, b)
      if (a.endPt[2] == b.endPt[2]) then
        return a.size < b.size
      end
      return a.endPt[2] < b.endPt[2]
    end)
    local function eachParticle(callback)
      for i=1, #particles do
        local p = particles[i]
        local x, y = p.curve:evaluate(p.clock)
        local endX, endY = p.endPt[1], p.endPt[2]
        local sx, sy = p.size/10, p.size/10

        callback(p, x, y, endX, endY, sx, sy)
      end
    end
    local cubeSpriteSize = 16
    local cubeOffsetX = cubeSpriteSize/2
    local function drawShadow(p, x, y, _, endY, sx, sy)
      local lifeRatio = p.lifeTime/lifeTime
      local opacity = 1 - lifeRatio
      local scale = math.min(1, y/endY*2)
      love.graphics.setColor(0,0,0,0.5*opacity)
      love.graphics.draw(particleImage, particleImageQuad,  x, endY, 0, (sx * scale), (sy/2 * scale), cubeOffsetX, -32)
    end
    local function drawIceCube(p, x, y, _, _, sx, sy)
      local lifeRatio = p.lifeTime/lifeTime
      local opacity = 1 - lifeRatio
      love.graphics.setColor(0.5,0.8,1,opacity)
      love.graphics.draw(particleImage, particleImageQuad, x, y, 0, sx, sy, cubeOffsetX, 0)
    end
    local function drawPath(p)
      love.graphics.setColor(1,1,1,0.3)
      love.graphics.line(p.curve:render())
    end

    return function(dt)
      local doneCount = 0
      for i=1, numParticles do
        local p = particles[i]
        local actualDt = dt / (p.dist / speed)
        p.clock = math.min(1, (p.clock + actualDt))
        local projectileAnimationComplete = p.clock >= 1
        if projectileAnimationComplete then
          p.lifeTime = p.lifeTime + dt
        end
        local done = p.lifeTime >= lifeTime
        if done then
          doneCount = doneCount + 1
        end
      end
      eachParticle(drawShadow)
      eachParticle(drawIceCube)
      -- eachParticle(drawPath)
      return doneCount == numParticles
    end
  end
end

local AnimationFactory = require 'components.animation-factory'
local frozenShatterParticleSystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 500)
local function frozenShatterExplosionEffect()
  local psystem = frozenShatterParticleSystem
  local animation = AnimationFactory:newStaticSprite('pixel-white-1x1')
  psystem:setQuads(animation.sprite)
  psystem:setOffset(animation:getOffset())
  psystem:setParticleLifetime(0.15)
  psystem:setColors(
    0.8,1,1,1,
    0.8,1,1,1,
    0.8,1,1,0
  )
  psystem:setEmissionRate(0)
  psystem:setSpeed(100)
  psystem:setSizes(2, 3)
  psystem:setSpread(-math.pi * 2, math.pi * 2) -- 360 degrees
  local acceleration = 100
  psystem:setLinearAcceleration(-acceleration, -acceleration, acceleration, acceleration) -- move particles in all random directions
  psystem:setEmissionArea('ellipse', 5, 5, 0, true)
end

local Component = require 'modules.component'
local effectsDrawQueue = {}
Component.create({
  init = function(self)
    Component.addToGroup(self, 'all')
  end,
  update = function(self, dt)
    frozenShatterParticleSystem:update(dt)
    self.dt = dt
  end,
  draw = function(self)
    local i = 0
    while i < #effectsDrawQueue do
      local index = i + 1
      local complete = effectsDrawQueue[index](self.dt)
      if complete then
        table.remove(effectsDrawQueue, index)
      else
        i = i + 1
      end
    end
    love.graphics.setColor(1,1,1)
    love.graphics.draw(frozenShatterParticleSystem)
  end,
  drawOrder = function()
    local drawOrders = require 'modules.draw-orders'
    return drawOrders.SparkDraw
  end
})

local AnimationFactory = require 'components.animation-factory'
local shatterEffect = frozenShatterEffect(
  AnimationFactory.atlas,
  AnimationFactory:new({'cube'}).sprite
)
return function(...)
  local args = {...}
  local x, y = args[1], args[2]
  frozenShatterExplosionEffect()
  frozenShatterParticleSystem:setPosition(x, y)
  frozenShatterParticleSystem:emit(30)
  table.insert(effectsDrawQueue, shatterEffect(args))
  local Sound = require 'components.sound'
  Sound.playEffect('ice_shatter.wav')
end