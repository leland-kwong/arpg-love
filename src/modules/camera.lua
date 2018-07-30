local Camera = function()
  local camera = {
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight(),
    scaleX = 1,
    scaleY = 1
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

  function camera:setScale(scaleX, scaleY)
    self.scaleX = scaleX
    self.scaleY = scaleY or scaleX
    return self
  end

  function camera:attach()
    love.graphics.push()
    love.graphics.translate(self.w/2, self.h/2)
    love.graphics.scale(self.scaleX, self.scaleY)
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
    local wx = ((x) - self.w/2) / self.scaleX
    local wy = ((y) - self.h/2) / self.scaleY
    return wx + self.x, wy + self.y
  end

  function camera:getMousePosition()
    return self:toWorldCoords(love.mouse.getPosition())
  end

  return camera
end

return Camera