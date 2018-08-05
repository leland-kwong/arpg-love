-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local function addDirection(grid, x, y, from, frontier, cameFromList, canVisit)
  cameFromList[y] = cameFromList[y] or {}
  local hasVisited = cameFromList[y][x] ~= nil
  local dist = from[3]
  if hasVisited or not canVisit(grid, x, y, dist) then
    return
  else
    table.insert(frontier, {x, y, dist + 1})
  end
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

local function visitNeighbors(grid, start, frontier, cameFromList, canVisit)
  local x,y = start[1], start[2]
  addDirection(grid, x+1, y, start, frontier, cameFromList, canVisit)
	addDirection(grid, x-1, y, start, frontier, cameFromList, canVisit)
	addDirection(grid, x, y+1, start, frontier, cameFromList, canVisit)
	addDirection(grid, x, y-1, start, frontier, cameFromList, canVisit)
end

--[[
  Returns a flow field, where each cell contains the following data:
  {directionX, directionY, distance from start}
]]
local function flowField(grid, x, y, canVisitCallback)
  local start = {x, y, 1}
  local frontier = {
    start
  }
  local cameFromList = {}
  cameFromList[y] = cameFromList[y] or {}
  -- {directionX, directionY, distance}
  cameFromList[y][x] = {0,0,0}

  while #frontier > 0 do
    local current = table.remove(frontier, 1)
    visitNeighbors(grid, current, frontier, cameFromList, canVisitCallback)
  end

	return cameFromList
end

return flowField