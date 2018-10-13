-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local TablePool = require 'utils.table-pool'
local setProp = require 'utils.set-prop'

local function FlowFieldFactory(canVisitCallback, getter)
  local flowCellTablePool = TablePool.new()
  local frontierTablePool = TablePool.new()
  local cameFromRowTablePool = TablePool.new()

  local function flowCellData(x, y, dist, id)
    local obj = flowCellTablePool.get(id)
    obj.x = x
    obj.y = y
    obj.dist = dist
    return obj
  end

  local function toVisitData(x, y, dist, id)
    local obj = frontierTablePool.get(id)
    obj.x = x
    obj.y = y
    obj.dist = dist
    return obj
  end

  local function cameFromRowPool(id)
    local obj = cameFromRowTablePool.get(id)
    -- clear out table
    for k,v in pairs(obj) do
      obj[k] = nil
    end
    return obj
  end

  local function addCellData(grid, x, y, from, frontier, cameFromList, canVisit)
    local row = cameFromList[y]
    local hasVisited = row and row[x] ~= nil
    local dist = from.dist
    if hasVisited or not canVisit(grid, x, y, dist) then
      return
    else
      -- insert cell to unvisited list
      frontier[#frontier + 1] = toVisitData(x, y, dist + 1, cameFromList._cellCount)
    end
    cameFromList._cellCount = cameFromList._cellCount + 1
    cameFromList[y] = cameFromList[y] or cameFromRowPool(cameFromList._cellCount)

    -- directions
    -- we multiply by -1 because we want the direction to where it came from
    local dirX = (x - from.x) * -1
    local dirY = (y - from.y) * -1
    cameFromList[y][x] = flowCellData(dirX, dirY, dist, cameFromList._cellCount)
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

  local function flowField(grid, startX, startY, includeDiagonalDirection)
    start = setProp(start)
      :set('x', startX)
      :set('y', startY)
      :set('dist', 1)

    -- reset frontier
    for i=1, #frontier do
      frontier[i] = nil
    end
    table.insert(frontier, start)

    local cameFromList = {
      -- gets incremented each time a flow field cell is generated. Also used as the id for the table pool
      _cellCount = 0,
      start = start,
      getValue = getter
    }
    cameFromList[startY] = cameFromRowPool(cameFromList._cellCount)
    -- {directionX, directionY, distance}
    cameFromList[startY][startX] = flowCellData(0, 0, 0, cameFromList._cellCount)

    local i = 1
    while i <= #frontier do
      local current = frontier[i]
      i = i + 1
      visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback, includeDiagonalDirection)
    end

    return cameFromList
  end

  return flowField
end

return FlowFieldFactory