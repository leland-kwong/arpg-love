local Grid = require 'utils.grid'

--uses 16-bit bitmasking to calculate tile value
local function getTileValue(grid, x, y, isTileValue)
	local northCoord = y - 1
	local north = (grid[northCoord] and isTileValue(grid[northCoord][x])) and 1 or 0

	local eastCoord = x + 1
	local east = (grid[y][eastCoord] and isTileValue(grid[y][eastCoord])) and 1 or 0

	local southCoord = y + 1
	local south = (grid[southCoord] and isTileValue(grid[southCoord][x])) and 1 or 0

	local westCoord = x - 1
	local west = (grid[y][westCoord] and isTileValue(grid[y][westCoord])) and 1 or 0

	return north + (2 * east) + (4 * south) + (8 * west)
end

return getTileValue