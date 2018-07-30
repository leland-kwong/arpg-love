local Camera = function()
  local camera = {
    x = 0,
    y = 0,
    w = love.graphics.getWidth(),
    h = love.graphics.getHeight()
  }

  function camera:setPosition(x, y)
    self.x = x
    self.y = y
  end

  function camera:attach()
    love.graphics.push()
    love.graphics.translate(self.w/2, self.h/2)
    love.graphics.translate(
      -self.x,
      -self.y
    )
  end

  function camera:detach()
    love.graphics.pop()
  end

  function camera:toWorldCoords(x, y)
    return x + self.x - self.w/2, y + self.y - self.h/2
  end

  function camera:getMousePosition()
    return self:toWorldCoords(love.mouse.getPosition())
  end

  return camera
end

return Camera