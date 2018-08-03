local bline = require("utils.bresenham-line")

local INF = 1/0

local CARDINT = {
	[0] = true,
	[1] = true,
	[-1] = true,
	[INF] = true -- infinity
}

local TYPE_FUNCTION = 'function'
local mutableProps = {
	hasObstacles = false,
	grid = nil,
	walkable = nil,
	walkableFn = false
}

local function blineCallback(props, x, y)
	local value = props.grid[y][x]
	if not props.walkableFn then
		if value ~= props.walkable then
			props.hasObstacles = true
			return false
		end
	elseif not props.walkable(value) then
		props.hasObstacles = true
		return false
	end
end

local function hasObstaclePoints(grid, x1, y1, x2, y2, walkable)
	local walkableFn = type(walkable) == TYPE_FUNCTION
	local slope = (y2 -y1) / (x2 - x1)
	mutableProps.hasObstacles = false
	mutableProps.grid = grid
	mutableProps.walkableFn = walkableFn
	mutableProps.walkable = walkable

	bline(x1, y1, x2, y2, blineCallback, mutableProps)
	return mutableProps.hasObstacles
end

return hasObstaclePoints