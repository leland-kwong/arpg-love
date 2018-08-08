-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local sqrt, pow = math.sqrt, math.pow

local function addCellData(grid, x, y, from, frontier, cameFromList, canVisit)
  cameFromList[y] = cameFromList[y] or {}
  local hasVisited = cameFromList[y][x] ~= nil
  local dist = from.dist
  if hasVisited or not canVisit(grid, x, y, dist) then
    return
  else
    -- insert cell to unvisited list
    frontier[#frontier + 1] = {x = x, y = y, dist = dist + 1}
  end

  -- directions
  -- we multiply by -1 because we want the direction to where it came from
  local dirX = (x - from.x) * -1
  local dirY = (y - from.y) * -1

  cameFromList[y][x] = {
    x = dirX,
    y = dirY,
    dist = dist
  }
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


  --[[
    NOTE: these `canVisit` checks are here to prevent diagonal movements from
    cutting into corner walls.
  ]]
  -- north-east
  if canVisit(grid, x, y-1, dist) and canVisit(grid, x+1, y, dist) then
    addCellData(grid, x+1, y-1, start, frontier, cameFromList, canVisit)
  end

  -- south-west
  if canVisit(grid, x, y+1, dist) and canVisit(grid, x-1, y, dist) then
    addCellData(grid, x-1, y+1, start, frontier, cameFromList, canVisit)
  end

  -- south-east
  if canVisit(grid, x, y+1, dist) and canVisit(grid, x+1, y, dist) then
    addCellData(grid, x+1, y+1, start, frontier, cameFromList, canVisit)
  end

  -- north-west
  if canVisit(grid, x, y-1, dist) and canVisit(grid, x-1, y, dist) then
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
  local cameFromList = {}
  cameFromList[startY] = cameFromList[startY] or {}
  -- {directionX, directionY, distance}
  cameFromList[startY][startX] = {
    x = 0,
    y = 0,
    dist = 0
  }

  while #frontier > 0 do
    local current = table.remove(frontier, 1)
    visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback)
  end

	return cameFromList
end

return flowField