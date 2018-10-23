-- [based on](https://github.com/SSYGEN/STALKER-X/blob/master/Camera.lua)
local tween = require 'modules.tween'
local mergeProps = require 'utils.object-utils'.assign
local round = require 'utils.math'.round
local mathUtils = require 'utils.math'
local config = require 'config.config'

local Camera = function()
  local camera = {
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
    scale = 1,
    shakeOffset = {
      x = 0,
      y = 0
    }
  }

  local targetPosition = {x = 0, y = 0}
  local lerpDuration = 0
  local lerpTween = nil

  local function lerp(dt, reset)
    local dist = mathUtils.dist(camera.x, camera.y, targetPosition.x, targetPosition.y)
    local actualDuration = lerpDuration
    local isFarTransition = (dist / config.gridSize) > 50
    if isFarTransition then
      -- increase duration so that the screen doesn't scroll too fast, otherwise it looks too jarring
      actualDuration = 0.5
    end
    if reset then
      lerpTween = tween.new(actualDuration, camera, targetPosition, tween.easing.outExpo)
    end
    lerpTween:update(dt)
  end

  function camera:setSize(w, h)
    self.w = w
    self.h = h
    return self
  end

  function camera:setPosition(x, y, _lerpDuration)
    local round = require 'utils.math'.round
    x, y = round(x), round(y)
    lerpDuration = _lerpDuration or 0
    if (lerpDuration > 0) then
      targetPosition.x = x
      targetPosition.y = y
      return
    end
    self.x = x
    self.y = y
    return self
  end

  function camera:getPosition()
    return self.x, self.y
  end

  function camera:update(dt)
    if (lerpDuration > 0) then
      local lastTargetPositionX = self.lastTargetPositionX
      local lastTargetPositionY = self.lastTargetPositionY
      local hasChangedPosition = (lastTargetPositionX ~= targetPosition.x) or
        (lastTargetPositionY ~= targetPosition.y)
      self.lastTargetPositionX = targetPosition.x
      self.lastTargetPositionY = targetPosition.y
      lerp(dt, hasChangedPosition)
    end

    if self.shakeComponents then
      if (not self.shakeComponents.x.isShaking) then
        self.shakeComponents = nil
        return
      end
      self.shakeComponents.x:update(dt)
      self.shakeComponents.y:update(dt)
      self.shakeOffset.x = self.shakeComponents.x:amplitude()
      self.shakeOffset.y = self.shakeComponents.y:amplitude()
    end
  end

  function camera:getBounds(divisor)
    divisor = divisor or 1
    local scale = self.scale
    local halfWidth, halfHeight = self.w/scale/2, self.h/scale/2
    local west = self.x - halfWidth
    local east = self.x + halfWidth
    local north = self.y - halfHeight
    local south = self.y + halfHeight
    return
      west / divisor,
      east / divisor,
      north / divisor,
      south / divisor
  end

  function camera:getSize()
    return self.w/self.scale, self.h/self.scale
  end

  -- userful for debugging
  function camera:drawBounds()
    local w,e,n,s = self:getBounds()
    local width, height = self:getSize()
    local oLineWidth = love.graphics.getLineWidth()
    love.graphics.setColor(1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
      'line',
      w,
      n,
      width,
      height
    )
    love.graphics.setLineWidth(oLineWidth)
  end

  function camera:setScale(scale)
    self.scale = scale
    return self
  end

  function camera:attach()
    love.graphics.push()
    love.graphics.translate(self.w/2, self.h/2)
    love.graphics.scale(self.scale)
    local tx, ty = -self.x, -self.y
    if self.shakeComponents then
      tx = tx + (self.shakeOffset.x * self.shakeComponents.amplitude)
      ty = ty + (self.shakeOffset.y * self.shakeComponents.amplitude)
    end
    love.graphics.translate(tx, ty)
    return self
  end

  function camera:detach()
    love.graphics.pop()
    return self
  end

  function camera:toWorldCoords(x, y)
    local wx = ((x) - self.w/2) / self.scale
    local wy = ((y) - self.h/2) / self.scale
    return wx + self.x, wy + self.y
  end

  function camera:getMousePosition()
    return self:toWorldCoords(love.mouse.getPosition())
  end

  function camera:shake(duration, frequency, amplitude)
    local Shake = require 'modules.shake'
    self.shakeComponents = {
      amplitude = amplitude or 1,
      x = Shake(duration, frequency),
      y = Shake(duration, frequency)
    }
    self.shakeComponents.x:start()
    self.shakeComponents.y:start()
  end

  return camera
end

return Camera