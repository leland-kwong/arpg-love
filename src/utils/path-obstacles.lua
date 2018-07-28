local bline = require("utils.bresenham-line")

local INF = 1/0

local CARDINT = {
	[0] = true,
	[1] = true,
	[-1] = true,
	[INF] = true -- infinity
}

local function hasObstaclePoints(grid, startPt, endPt, walkable)
	local walkableFn = type(walkable) == "function"
	local x1,y1 = unpack(startPt)
	local x2,y2 = unpack(endPt)

	local slope = (y2 -y1) / (x2 - x1)
	--[[ 
	a* pathfinding algorithm only moves in the cardinal/intercardinal directions, 
	so if the slope is one of those values we can assume there are no obstacles in the way.
	]]--
	if CARDINT[slope] then
		return false
	end

	local hasObstacles = false
	-- OPTIMIZE: pull out this closure function
	local function blineCallback(grid, x, y) 
		local value = grid[y][x]
		if not walkableFn then
			if value ~= walkable then
				hasObstacles = true
				return false
			end
		elseif not walkable(value) then
			hasObstacles = true
			return false
		end 
	end
	bline(x1, y1, x2, y2, blineCallback, grid)
	return hasObstacles
end

return hasObstaclePoints