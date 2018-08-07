local function getFlowFieldValue(flowField, gridX, gridY)
  local row = flowField[gridY]
  local v = row[gridX]
  if not v then
    return 0, 0, 0
  end
  return v[1], v[2], v[3]
end

local M = {}

return function(self, flowField, grid, gridX, gridY, length, WALKABLE)
  local vx, vy = getFlowFieldValue(flowField, gridX, gridY)
  local nextPosition = {gridX, gridY}
  local path = {}

  while #path < length do
    local nextPosX, nextPosY = gridX + vx, gridY + vy

    -- next vectors
    local vx2, vy2 = getFlowFieldValue(flowField, nextPosX, nextPosY)

    if vx2 == -1 then
      if (grid[nextPosY + 1][nextPosX] ~= WALKABLE) or
        (grid[nextPosY + 1][nextPosX - 1] ~= WALKABLE)
      then
        vx2 = 0
        vy2 = -1
        nextPosX = gridX + 0
        nextPosY = gridY - 1
      end
    end

    nextPosition = {nextPosX, nextPosY}
    table.insert(path, nextPosition)

    vx, vy = vx + vx2, vy + vy2
  end
  return path
end