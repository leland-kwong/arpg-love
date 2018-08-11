local function debugLineOfSight(self)
  local gridSize = self.gridSize
  local targetX, targetY = self.findNearestTarget(self.x, self.y, self.sightRadius)

  local function debugLineOfSightDraw(x, y, blocked)
    love.graphics.setLineWidth(2)
    if blocked then
      love.graphics.setColor(1,0,0,0.5)
    else
      love.graphics.setColor(1,1,1,0.5)
    end
    love.graphics.rectangle(
      'fill',
      x * gridSize,
      y * gridSize,
      gridSize,
      gridSize
    )
  end

  self:checkLineOfSight(self.grid, self.WALKABLE, targetX, targetY, debugLineOfSightDraw)
end

return debugLineOfSight