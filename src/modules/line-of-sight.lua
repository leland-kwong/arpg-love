local perf = require'utils.perf'
local bresenhamLine = require'utils.bresenham-line'
local Perf = require'utils.perf'

local perf = Perf({
  enabled = false,
  done = function(t)
    print('bresenham line:', t)
  end
})

local function getDirection(x1, y1, x2, y2)
  local vx, vy = x2 - x1, y2 - y1
  return vx, vy
end

local function getSlope(x1, y1, x2, y2)
  return (y2 - y1) / (x2 - x1)
end

-- return [FUNCTION] - a line of sight checker based on the provided grid and walkable params
return function(grid, WALKABLE, debugFn)
  local prevX, prevY

  local function callback(_, gridX, gridY, i, DONE)
    local gridRow = grid[prevY]
    local isBlocked = gridRow and gridRow[prevX] ~= WALKABLE
    local isPrevPointBlocked = false
    local isLineBreak = false

    -- testing for walls at diagonal points
    if (not isBlocked) then
      local vx, vy = getDirection(prevX, prevY, gridX, gridY)
      local slope = getSlope(prevX, prevY, gridX, gridY)
      -- diagonal change
      isLineBreak = slope == -1 or slope == 1
      if isLineBreak then
        -- check for walls that are in the opposite vector direction
        local isBlockedNeighbor1 = grid[prevY] and (grid[prevY][prevX + vx] ~= WALKABLE)
        local isBlockedNeighbor2 = grid[prevY + vy] and (grid[prevY + vy][prevX] ~= WALKABLE)
        isBlocked = isBlockedNeighbor1 and isBlockedNeighbor2
      end
    end

    if debugFn then
      debugFn(prevX, prevY, isBlocked)
    end

    prevX, prevY = gridX, gridY
    return not isBlocked, isBlocked and DONE or nil
  end

  -- return [BOOLEAN] - true if line of sight is valid
  local gridCoordinateAssertionErrorMsg = 'coordinates must be grid positions'
  local function checkLineOfSight(x1, y1, x2, y2)
    -- if any values are not integers, we can assume that they're not grid positions
    local isGridCoordinates =
      grid[y1]      ~= nil and
      grid[y1][x1]  ~= nil and
      grid[y2]      ~= nil and
      grid[y2][x2]  ~= nil
    assert(
      isGridCoordinates,
      gridCoordinateAssertionErrorMsg
    )

    prevX, prevY = x1, y1
    return bresenhamLine(x1, y1, x2, y2, callback)
  end

  return perf(checkLineOfSight)
end