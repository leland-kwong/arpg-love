-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local TablePool = require 'utils.table-pool'
local memoize = require 'utils.memoize'

local function getIndexByCoordinate(x, y, maxCols)
  return (y * maxCols) + x
end

local gridRowsCols = memoize(function(grid)
  return #grid, #grid[1]
end)

local flowCellTablePool = TablePool.new()
local frontierTablePool = TablePool.new()

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

local function addCellData(grid, x, y, from, frontier, cameFromList, canVisit)
  cameFromList[y] = cameFromList[y] or {}
  local hasVisited = cameFromList[y][x] ~= nil
  local dist = from.dist
  if hasVisited or not canVisit(grid, x, y, dist) then
    return
  else
    -- insert cell to unvisited list
    frontier[#frontier + 1] = toVisitData(x, y, dist + 1, cameFromList._cellCount)
  end

  -- directions
  -- we multiply by -1 because we want the direction to where it came from
  local dirX = (x - from.x) * -1
  local dirY = (y - from.y) * -1
  cameFromList[y][x] = flowCellData(dirX, dirY, dist, cameFromList._cellCount)
  cameFromList._cellCount = cameFromList._cellCount + 1
end

--[[
  IMPORTANT: we should do the cardinal directions before the intercardinal directions. This way
  the directions are prioritised by the cardinal directions first.
]]
local function visitNeighbors(grid, start, frontier, cameFromList, canVisit)
  local x,y,dist = start.x, start.y, start.dist

  -- east
  addCellData(grid, x+1, y, start, frontier, cameFromList, canVisit)

  -- west
  addCellData(grid, x-1, y, start, frontier, cameFromList, canVisit)

  -- south
  addCellData(grid, x, y+1, start, frontier, cameFromList, canVisit)

  -- north
  addCellData(grid, x, y-1, start, frontier, cameFromList, canVisit)


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

--[[
  Returns a flow field, where each cell contains the following data:
  {directionX, directionY, distance from start}
]]
local function flowField(grid, startX, startY, canVisitCallback)
  local start = {
    x = startX,
    y = startY,
    dist = 1
  }
  -- list of nodes to visit
  local frontier = {
    start
  }
  local cameFromList = {
    -- gets incremented each time a flow field cell is generated. Also used as the id for the table pool
    _cellCount = 0
  }
  cameFromList[startY] = cameFromList[startY] or {}
  -- {directionX, directionY, distance}
  cameFromList[startY][startX] = {
    x = 0,
    y = 0,
    dist = 0
  }

  local i = 1
  while i <= #frontier do
    local current = frontier[i]
    i = i + 1
    visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback)
  end

	return cameFromList, i
end

return flowField