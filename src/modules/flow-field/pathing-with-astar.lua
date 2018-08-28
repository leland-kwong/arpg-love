local pprint = require 'utils.pprint'

local function getFlowFieldValue(flowField, gridX, gridY)
  local row = flowField[gridY]
  if not row then
    return 0, 0, 0
  end

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
local function getNextDirectionWithAdjustmentIfNeeded(grid, vx, vy, vx2, vy2, curGridX, curGridY, gridX, gridY, WALKABLE)
  local dir = getDirection(vx, vy)
  local dir2 = getDirection(vx2, vy2)

  if direction.W == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or grid[gridY + 1][gridX + 1] ~= WALKABLE then
      return - 1, 0
    end
    if grid[gridY + 1][gridX] ~= WALKABLE then
      return 0, - 1
    end
  end

  if direction.SW == dir then
    if grid[gridY][gridX + 1] ~= WALKABLE or
      grid[gridY + 1][gridX + 1] ~= WALKABLE then
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
    if grid[curGridY][curGridX + 2] ~= WALKABLE then
      return 0, 1
    end

    if direction.S == dir2 and grid[gridY + 1][gridX - 1] == WALKABLE then
      return 0, 1
    end

    if grid[gridY][gridX + 1] ~= WALKABLE or
      grid[gridY + 1][gridX + 1] ~= WALKABLE then
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
    if dir2 == direction.N and grid[gridY - 1][gridX - 1] == WALKABLE then
      return 0, -1
    end

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

local function aiPath()
  local path = {}

  return function (flowField, grid, gridX, gridY, length, WALKABLE, clearance)
    -- clear previous path data
    for i=1, #path do
      path[i] = nil
    end

    local curPosition = {x = gridX, y = gridY}

    while #path < length do
      local px, py = curPosition.x, curPosition.y
      local vx, vy = getFlowFieldValue(flowField, px, py)
      local nextPx, nextPy = px + vx, py + vy
      local nextVx, nextVy = getFlowFieldValue(flowField, nextPx, nextPy)
      local vxActual, vyActual = vx, vy

      local isZeroVector = nextVx == 0 and nextVy == 0
      if isZeroVector then
        return path
      end

      if clearance > 1 then
        -- check one step ahead and adjust the current direction if needed
        vxActual, vyActual = getNextDirectionWithAdjustmentIfNeeded(grid, vx, vy, nextVx, nextVy, px, py, nextPx, nextPy, WALKABLE)
      end

      local nextPosition = {x = px + vxActual, y = py + vyActual}

      -- table insert
      tbl[#tbl + 1] = nextPosition
      curPosition = nextPosition
    end

    return path
  end
end

return aiPath