-- position tools
local pixelsToGrid = require("utils.pixels-to-grid-units")
local gridToPixels = require("utils.grid-units-to-screen-units")
local memoize = require("utils.memoize")

local Position = {
  pixelsToGrid = pixelsToGrid,
  gridToPixels = gridToPixels
}

local function findNearestWalkableTileFromPosition(grid, gridX, gridY, walkable)
	local x,y = gridX, gridY
	local positions = {
		{x-1, y-1}, -- nw
		{x, y-1}, -- n
		{x+1, y-1}, -- ne
		{x-1, y}, -- w
		{x+1, y}, -- e
		{x-1, y+1}, -- sw
		{x, y+1}, -- s
		{x+1, y+1}, -- se
	}

	for i=1, #positions do
		local pos = positions[i]
		local x,y = unpack(pos)
		local row = grid[y]
		if row and (grid[y][x] == walkable) then
			return x, y
		end
	end
end

local mathAbs = math.abs

-- returns normalized values
Position.getDirection = memoize(function(x1, y1, x2, y2)
  local a = y2 - y1
  local b = x2 - x1
  local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
	return b/c, a/c
end)

function Position.normalizeVector(a, b)
	local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
	return a == 0 and 0 or a/c,
		b == 0 and 0 or b/c
end

Position.findNearestWalkableTile = {
	fromGridPosition = function(grid, x, y)
		return findNearestWalkableTileFromPosition(grid, x, y)
	end,
	fromPixelPosition = function(grid, x, y)
		local gridX, gridY = pixelsToGrid(x, y)
		return findNearestWalkableTileFromPosition(grid, gridX, gridY)
	end
}

return Position