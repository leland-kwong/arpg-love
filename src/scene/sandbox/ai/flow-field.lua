-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/

local function outOfBoundsCheck(grid, x, y)
  return y < 1 or x < 1 or y > #grid or x > #grid[1]
end

local function addDirection(grid, x, y, from, frontier, cameFromList)
  cameFromList[y] = cameFromList[y] or {}
  local hasVisited = cameFromList[y][x] ~= nil
  local isOutOfBounds = outOfBoundsCheck(grid, x, y)
  if hasVisited or isOutOfBounds then
    return
  else
    table.insert(frontier, {x, y})
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
  cameFromList[y][x] = {dirX, dirY}
end

local function visitNeighbors(grid, start, frontier, cameFromList)
  local x,y = start[1], start[2]
  addDirection(grid, x+1, y, start, frontier, cameFromList)
	addDirection(grid, x-1, y, start, frontier, cameFromList)
	addDirection(grid, x, y+1, start, frontier, cameFromList)
	addDirection(grid, x, y-1, start, frontier, cameFromList)
end

-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/
-- Note: mutates the grid
local function flowField(grid, x, y)
  local start = {x, y}
  local frontier = {
    start
  }
  local cameFromList = {}
  cameFromList[y] = cameFromList[y] or {}
  cameFromList[y][x] = {0,0}

  while #frontier > 0 do
    local current = table.remove(frontier, 1)
    visitNeighbors(grid, current, frontier, cameFromList)
  end

	return cameFromList
end

return flowField