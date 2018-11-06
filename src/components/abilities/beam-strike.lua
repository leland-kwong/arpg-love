--[[
  Beam Strike

  Calls down a beam from the sky with an initial impact delay
]]

local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local AnimationFactory = require 'components.animation-factory'
local AudioManager = require 'components.sound'
local config = require 'config.config'
local ImpactDispersion = require 'components.abilities.effect-dispersion'

local impactSoundHitFrameTime = 0.535

local animationOuter = AnimationFactory:newStaticSprite(
  'boss-1/beam-strike-glyph-outer'
)

local animationInner = AnimationFactory:newStaticSprite(
  'boss-1/beam-strike-glyph-inner'
)

local beamHead = AnimationFactory:newStaticSprite(
  'boss-1/beam-strike-head'
)

local beamTail = AnimationFactory:newStaticSprite(
  'boss-1/beam-strike-tail'
)

local beamMiddle = AnimationFactory:newStaticSprite(
  'boss-1/beam-strike-middle'
)

-- returns beamX, beamY, beamLength, isImpactFrame
function createBeam(x1, y1, animationSpeed)
  local max = math.max
  return coroutine.create(function()
    local distToTravel = 400
    local initialLength = 200
    local length = initialLength -- beam length
    local frameRate = 1/60
    local animationSpeed = math.floor(distToTravel / animationSpeed * frameRate)
    local x2, y2 = x1, y1
    -- tween beam position
    while (distToTravel > 0) do
      distToTravel = max(0, distToTravel - animationSpeed)
      x2, y2 = x1, y1 - distToTravel
      coroutine.yield(x2, y2, length)
    end
    -- tween beam length
    while length > 0 do
      local isImpactFrame = length == initialLength
      length = length - animationSpeed
      coroutine.yield(x2, y2, max(0, length), isImpactFrame)
    end
  end)
end

local BeamStrike = {
  group = groups.all,
  delay = 0.25, -- impact delay
  radius = 20,
  opacity = 1,
  drawOrder = function()
    return 2
  end,
  scale = {
    x = 1,
    y = 0.7
  },
  onHit = require 'utils.noop'
}

function BeamStrike.init(self)
  Component.addToGroup(self, 'gameWorld')

  self.canvas = love.graphics.newCanvas()
  self.clock = 0
  self.animationSpeed = 0.25

  self.postHitDuration = 0.25
  self.postHitClock = 0

  self.hitSoundPlayed = false
end

function BeamStrike.update(self, dt)
  self.clock = self.clock + dt
  self.angle = self.angle + dt
  local shouldStartMoving = self.clock >= (self.delay - self.animationSpeed)
  if shouldStartMoving then
    self.beamCo = self.beamCo or createBeam(self.x, self.y, self.animationSpeed)
    local isAlive, x, y, beamLength, isImpactFrame = coroutine.resume(self.beamCo)
    if isImpactFrame then
      ImpactDispersion.create({
        x = self.x,
        y = self.y,
        radius = self.radius,
        scale = {
          x = self.scale.x,
          y = self.scale.y
        }
      })
      self:onHit()
    end
    if (isAlive and beamLength) then
      self.beamX, self.beamY, self.beamLength = x, y, beamLength
    -- post hit effect
    else
      self.postHitClock = self.postHitClock + dt
      self.opacity = (self.postHitDuration - self.postHitClock) / self.postHitDuration
      local isComplete = self.postHitClock >= self.postHitDuration
      if isComplete then
        self:delete(true)
      end
    end
  end

  local soundDelay = self.delay - impactSoundHitFrameTime
  local soundSeekAhead = (soundDelay < 0 and soundDelay) or 0
  local isSoundStart = self.clock >= soundDelay
  if (isSoundStart and (not self.hitSoundPlayed)) then
    self.hitSoundPlayed = true
    if isSoundStart then
      AudioManager.playEffect('beam-strike-impact.wav', function(source)
        source:seek(soundSeekAhead)
      end)
    end
  end
end

function BeamStrike.draw(self)
  love.graphics.setColor(1,1,1,1 * self.opacity)
  if self.beamCo then
    local ox, oy = beamHead:getOffset()
    local beamLength = self.beamLength
    local actualX, actualY = self.beamX - ox, self.beamY - oy
    if (beamLength > 0) then
      -- tail
      local _, tailHeight = beamTail:getOffset()
      love.graphics.draw(AnimationFactory.atlas, beamTail.sprite, actualX, actualY - beamLength - tailHeight + 1)
      -- middle
      love.graphics.draw(AnimationFactory.atlas, beamMiddle.sprite, actualX, actualY + 1, 0, 1, beamLength, 0, 2)
      -- head
      love.graphics.draw(AnimationFactory.atlas, beamHead.sprite, actualX, actualY)

      if self.debug then
        love.graphics.setColor(1,1,0,0.4)
        love.graphics.circle('fill', self.x, self.y, 5)
      end
    end
  end

  -- draw glyph
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(config.scale)
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()

  -- draw rotated sprites to canvas first
  local _, _, glyphWidth, glyphHeight = animationOuter.sprite:getViewport()
  local glyphOx, glyphOy = animationOuter:getSourceOffset()
  local glyphX, glyphY = glyphWidth - glyphOx, glyphHeight - glyphOy
  local ox, oy = animationOuter:getOffset()
  love.graphics.draw(
    AnimationFactory.atlas,
    animationOuter.sprite,
    glyphX,
    glyphY,
    self.angle * 2,
    1, 1,
    ox,
    oy
  )

  local ox, oy = animationInner:getOffset()
  love.graphics.draw(
    AnimationFactory.atlas,
    animationInner.sprite,
    glyphX,
    glyphY,
    self.angle * -1 / 2,
    1, 1,
    ox,
    oy
  )

  love.graphics.setCanvas()
  love.graphics.pop()
  love.graphics.setBlendMode('alpha')

  local canvasX, canvasY = self.x - glyphX - glyphWidth/2, self.y - glyphY - glyphHeight/2
  -- scale in y direction to get perspective
  local yOffset = (1 - self.scale.y) * glyphHeight
  love.graphics.draw(self.canvas, canvasX, canvasY + yOffset, 0, 1, self.scale.y)

  if self.debug then
    love.graphics.setColor(1,0.5,1)
    love.graphics.circle('fill', canvasX, canvasY, 5)
  end
end

function BeamStrike.drawOrder()
  return 2
end

return Component.createFactory(BeamStrike)