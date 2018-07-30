-- [based on](https://github.com/SSYGEN/STALKER-X/blob/master/Camera.lua)

local Camera = function()
  local camera = {
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
    scale = 1,
  }

  function camera:setSize(w, h)
    self.w = w
    self.h = h
    return self
  end

  function camera:setPosition(x, y)
    self.x = x
    self.y = y
    return self
  end

  -- returns bounds in screen pixels
  function camera:getBounds()
    local minX = (self.x * self.scale) - self.w/2
    local maxX = (self.x * self.scale) + self.w/2
    local minY = (self.y * self.scale) - self.h/2
    local maxY = (self.y * self.scale) + self.h/2
    return minX, maxX, minY, maxY
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