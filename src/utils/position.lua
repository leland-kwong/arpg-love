-- position tools
local pixelsToGrid = require("utils.pixels-to-grid-units")
local gridToPixels = require("utils.grid-units-to-screen-units")
local gameConfig = require("main.config.game-config")
local memoize = require("utils.memoize")

local Position = {
  pixelsToGrid = pixelsToGrid,
  gridToPixels = gridToPixels
}

local function findNearestWalkableTileFromPosition(grid, gridX, gridY)
	local x,y = gridX, gridY
	local walkable = gameConfig.pixel_type.walkable
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

Position.getDirection = memoize(function(from, to)
	local pointerOffsetY = 8 -- adjust it so that its slightly above the point
	local cursorDirX = to.x >= from.x and 1 or -1
	local cursorDirY = to.y >= from.y and 1 or -1
	local dx = mathAbs(to.x - from.x)
	local dy = mathAbs(to.y - from.y)
	local x = dx * cursorDirX
	local y = (dy * cursorDirY) + pointerOffsetY
	return vmath.normalize(
		vmath.vector3(x, y, 0)
	)
end)

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