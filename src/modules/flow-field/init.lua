-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local setProp = require 'utils.set-prop'

local function FlowFieldFactory(canVisitCallback, getter)
  local function flowCellData(x, y, dist)
    return {
      x = x,
      y = y,
      dist = dist
    }
  end

  local function toVisitData(x, y, dist)
    return {
      x = x,
      y = y,
      dist = dist
    }
  end

  local function addCellData(grid, x, y, from, frontier, cameFromList, canVisit)
    local row = cameFromList[y]
    local hasVisited = row and row[x] ~= nil
    local dist = from.dist
    if hasVisited or not canVisit(grid, x, y, dist) then
      return
    else
      -- insert cell to unvisited list
      frontier[#frontier + 1] = toVisitData(x, y, dist + 1)
    end
    cameFromList[y] = cameFromList[y] or {}

    -- directions
    -- we multiply by -1 because we want the direction to where it came from
    local dirX = (x - from.x) * -1
    local dirY = (y - from.y) * -1
    cameFromList[y][x] = flowCellData(dirX, dirY, dist)
  end

  --[[
    IMPORTANT: we should do the cardinal directions before the intercardinal directions. This way
    the directions are prioritised by the cardinal directions first.
  ]]
  local function visitNeighbors(grid, start, frontier, cameFromList, canVisit, includeDiagonalDirection)
    local x,y,dist = start.x, start.y, start.dist

    -- east
    addCellData(grid, x+1, y, start, frontier, cameFromList, canVisit)

    -- west
    addCellData(grid, x-1, y, start, frontier, cameFromList, canVisit)

    -- south
    addCellData(grid, x, y+1, start, frontier, cameFromList, canVisit)

    -- north
    addCellData(grid, x, y-1, start, frontier, cameFromList, canVisit)

    if includeDiagonalDirection then
      local canWalkNorth = canVisit(grid, x, y-1, dist)
      local canWalkEast = canVisit(grid, x+1, y, dist)
      local canWalkSouth = canVisit(grid, x, y+1, dist)
      local canWalkWest = canVisit(grid, x-1, y, dist)

      --[[
        NOTE: these `canVisit` checks are here to prevent diagonal movements from
        cutting into corner walls.
      ]]
      -- north-east
      if (canWalkNorth and canWalkEast) then
        addCellData(grid, x+1, y-1, start, frontier, cameFromList, canVisit)
      end

      -- south-west
      if (canWalkSouth and canWalkWest) then
        addCellData(grid, x-1, y+1, start, frontier, cameFromList, canVisit)
      end

      -- south-east
      if (canWalkSouth and canWalkEast) then
        addCellData(grid, x+1, y+1, start, frontier, cameFromList, canVisit)
      end

      -- north-west
      if (canWalkNorth and canWalkWest) then
        addCellData(grid, x-1, y-1, start, frontier, cameFromList, canVisit)
      end
    end
  end

  --[[
    Returns a flow field, where each cell contains the following data:
    {directionX, directionY, distance from start}
  ]]

  -- [[ pooled objects ]]
  -- list of nodes to visit
  local frontier = {}
  local start = {}

  local function flowField(grid, startX, startY, includeDiagonalDirection, iteratorGranularity)
    iteratorGranularity = iteratorGranularity or 200

    start = setProp(start)
      :set('x', startX)
      :set('y', startY)
      :set('dist', 1)

    -- reset frontier
    for i=1, #frontier do
      frontier[i] = nil
    end
    table.insert(frontier, start)

    local cameFromList = {}
    cameFromList[startY] = {}
    -- {directionX, directionY, distance}
    cameFromList[startY][startX] = flowCellData(0, 0, 0, cameFromList._cellCount)

    return coroutine.wrap(function()
      local i = 1
      while i <= #frontier do
        local current = frontier[i]
        i = i + 1
        visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback, includeDiagonalDirection)

        if (i % iteratorGranularity) == 0 then
          coroutine.yield(cameFromList)
        end
      end
      coroutine.yield(cameFromList)
    end)
  end

  return flowField
end

return FlowFieldFactory