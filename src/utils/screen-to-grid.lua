local Global = require("main.global")
local memoize = require("utils.memoize")
local pixelsToGrid = require("utils.pixels-to-grid-units")

-- returns a grid position by flipping y axis so that the first row starts at the bottom rather than the top
local function gridPos(grid, x, y)
	local newY = #grid + 1 - y
	return x, newY
end

-- returns grid coordinates relative to the screen.
-- Also flips the grid y-axis value to go from bottom to top
local screenToGrid = function(sx, sy)
	local grid = Global.map
	local gx, gy = pixelsToGrid(sx, sy)
	return gridPos(grid, gx, gy)
end

return screenToGrid