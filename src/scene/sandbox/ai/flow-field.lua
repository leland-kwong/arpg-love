-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local function addCellData(grid, x, y, from, frontier, cameFromList, canVisit)
  cameFromList[y] = cameFromList[y] or {}
  local hasVisited = cameFromList[y][x] ~= nil
  local dist = from[3]
  if hasVisited or not canVisit(grid, x, y, dist) then
    return
  else
    -- insert cell to unvisited list
    frontier[#frontier + 1] = {x, y, dist + 1}
  end

  -- get directions
  local dirX = 0
  if x - from[1] > 0 then
    dirX = -1
  elseif x - from[1] < 0 then
    dirX = 1
  end

  local dirY = 0
  if y - from[2] > 0 then
    dirY = -1
  elseif y - from[2] < 0 then
    dirY = 1
  end

  cameFromList[y][x] = {dirX, dirY, dist}
end

--[[
  IMPORTANT: we should do the cardinal directions before the intercardinal directions. This way
  the directions are prioritised by the cardinal directions first.
]]
local function visitNeighbors(grid, start, frontier, cameFromList, canVisit)
  local x,y,dist = start[1], start[2], start[3]

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
  local start = {startX, startY, 1}
  -- list of nodes to visit
  local frontier = {
    start
  }
  local cameFromList = {}
  cameFromList[startY] = cameFromList[startY] or {}
  -- {directionX, directionY, distance}
  cameFromList[startY][startX] = {0,0,0}

  while #frontier > 0 do
    local current = table.remove(frontier, 1)
    visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback)
  end

	return cameFromList
end

return flowField