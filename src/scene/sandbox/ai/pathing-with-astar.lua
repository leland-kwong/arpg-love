local pprint = require 'utils.pprint'

local function getFlowFieldValue(flowField, gridX, gridY)
  local row = flowField[gridY]
  local v = row[gridX]
  if not v then
    return 0, 0, 0
  end
  return v.x, v.y, v.dist
end

local M = {}

local direction = {
  NW = 1,
  N = 2,
  NE = 3,
  E = 6,
  SE = 9,
  S = 8,
  SW = 7,
  W = 4,
  NONE = 5
}

local directionMap = {
  [-1] = {
    [-1] = direction.NW,
    [0] = direction.W,
    [1] = direction.SW
  },
  [0] = {
    [-1] = direction.N,
    [0] = direction.NONE,
    [1] = direction.S,
  },
  [1] = {
    [-1] = direction.NE,
    [0] = direction.E,
    [1] = direction.SE
  }
}

local function getDirection(vx, vy)
  return directionMap[vx][vy]
end

-- check clearance and adjust direction to avoid collision
local function getNextDirectionWithAdjustmentIfNeeded(grid, vx, vy, vx2, vy2, gridX, gridY, WALKABLE)
  local dir = getDirection(vx, vy)

  if direction.W == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return - 1, 0
    end
    if grid[gridY + 1][gridX] ~= WALKABLE then
      return 0, - 1
    end
  end

  if direction.SW == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return - 1, 0
    end
    if grid[gridY + 1][gridX] ~= WALKABLE then
      return -1, 0
    end
    if grid[gridY + 1][gridX - 1] ~= WALKABLE then
      return -1, 0
    end
  end

  if direction.S == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return - 1, 0
    end
  end

  if direction.SE == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or grid[gridY + 1][gridX + 1] ~= WALKABLE then
      if vx2 == 0 and vy2 == 1 then
        return 0, 1
      end
      if vx2 == 1 and vy2 == 0 then
        return 1, 0
      end
    end
    if grid[gridY + 1][gridX] ~= WALKABLE then
      if vx2 == 1 and vy2 == 0 then
        return 1, 0
      end
    end
  end

  if direction.N == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE then
      return -1, 0
    end
  end

  if direction.NE == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE then
      return 0, -1
    end
    if grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return 0, -1
    end
  end

  if direction.E == dir then
    if grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return 0, -1
    end
  end

  return vx, vy
end

local function aiPath(self, flowField, grid, gridX, gridY, length, WALKABLE)
  local curPosition = {gridX, gridY}
  local path = {}

  while #path < length do
    local px, py = curPosition[1], curPosition[2]
    local vx, vy = getFlowFieldValue(flowField, px, py)
    local nextPx, nextPy = px + vx, py + vy
    local nextVx, nextVy = getFlowFieldValue(flowField, nextPx, nextPy)
    -- check one step ahead and adjust the current direction if needed
    local vxActual, vyActual = getNextDirectionWithAdjustmentIfNeeded(grid, vx, vy, nextVx, nextVy, nextPx, nextPy, WALKABLE)
    local nextPosition = {px + vxActual, py + vyActual}

    if (nextVx == 0 and nextVy == 0) then
      return path
    end

    table.insert(path, nextPosition)
    curPosition = nextPosition
  end

  return path
end

return aiPath