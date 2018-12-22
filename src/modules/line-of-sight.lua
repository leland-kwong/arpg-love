local bresenhamLine = require'utils.bresenham-line'

local function getDirection(x1, y1, x2, y2)
  local vx, vy = x2 - x1, y2 - y1
  return vx, vy
end

local function getSlope(x1, y1, x2, y2)
  return (y2 - y1) / (x2 - x1)
end

-- return [FUNCTION] - a line of sight checker based on the provided grid and walkable params
return function(grid, WALKABLE, debugFn, isDevelopment)
  local prevX, prevY

  local function callback(_, gridX, gridY, i, DONE)
    local isBlocked = not WALKABLE(grid[prevY] and grid[prevY][prevX]) or
      not WALKABLE(grid[gridY] and grid[gridY][gridX])
    local isLineBreak = false

    -- testing for walls at diagonal points
    if (not isBlocked) then
      local vx, vy = getDirection(prevX, prevY, gridX, gridY)
      local slope = getSlope(prevX, prevY, gridX, gridY)
      -- diagonal change
      isLineBreak = slope == -1 or slope == 1
      if isLineBreak then
        -- check for walls that are in the opposite vector direction
        local x, y = prevX, prevY
        local isBlockedNeighbor1 = not WALKABLE(grid[y] and (grid[y][x + vx]))
        local isBlockedNeighbor2 = not WALKABLE(grid[y + vy] and (grid[y + vy][x]))
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
  local function checkLineOfSight(x1, y1, x2, y2)
    -- if any values are not integers, we can assume that they're not grid positions
    if (isDevelopment) then
      local isGridCoordinates =
        grid[y1]      ~= nil and
        grid[y1][x1]  ~= nil and
        grid[y2]      ~= nil and
        grid[y2][x2]  ~= nil
      if (not isGridCoordinates) then
        error(
          'coordinates must be grid positions '..require'utils.inspect'({x1, y1, x2, y2})
        )
      end
    end

    prevX, prevY = x1, y1
    return bresenhamLine(x1, y1, x2, y2, callback)
  end

  return checkLineOfSight
end