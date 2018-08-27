-- [based on](https://github.com/SSYGEN/STALKER-X/blob/master/Camera.lua)
local tween = require 'modules.tween'
local mergeProps = require 'utils.object-utils'.assign
local round = require 'utils.math'.round
local mathUtils = require 'utils.math'
local config = require 'config.config'

local defaultOptions = {
  lerp = function()
    return 0
  end
}

local Camera = function(options)
  options = mergeProps({}, defaultOptions, options)

  local camera = {
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
    scale = 1
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
      actualDuration = 2
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

  function camera:setPosition(x, y)
    -- force positions to be on full pixels to prevent artifacting due to sub-pixel rendering
    x = round(x)
    y = round(y)

    if (lerpDuration > 0) then
      targetPosition.x = x
      targetPosition.y = y
      return
    end
    self.x = x
    self.y = y
    return self
  end

  function camera:update(dt)
    lerpDuration = options.lerp()
    if (lerpDuration > 0) then
      local lastTargetPositionX = self.lastTargetPositionX
      local lastTargetPositionY = self.lastTargetPositionY
      local hasChangedPosition = (lastTargetPositionX ~= targetPosition.x) or
        (lastTargetPositionY ~= targetPosition.y)
      self.lastTargetPositionX = targetPosition.x
      self.lastTargetPositionY = targetPosition.y
      lerp(dt, hasChangedPosition)
    end
  end

  function camera:getBounds()
    local scale = self.scale
    local west = (self.x * scale) - self.w/2
    local east = (self.x * scale) + self.w/2
    local north = (self.y * scale) - self.h/2
    local south = (self.y * scale) + self.h/2
    return west, east, north, south
  end

  function camera:setScale(scale)
    self.scale = scale
    return self
  end

  function camera:attach()
    love.graphics.push()
    love.graphics.translate(self.w/2, self.h/2)
    love.graphics.scale(self.scale)
    love.graphics.translate(
      -self.x,
      -self.y
    )
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

  return camera
end

return Camera