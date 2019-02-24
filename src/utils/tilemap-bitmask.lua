local Grid = require 'utils.grid'

--uses 16-bit bitmasking to calculate tile value
local function getTileValue(grid, x, y, isTileValue)
	local northCoord = y - 1
	local north = isTileValue(Grid.get(grid, x, northCoord)) and 1 or 0

	local eastCoord = x + 1
	local east = isTileValue(Grid.get(grid, eastCoord, y)) and 1 or 0

	local southCoord = y + 1
	local south = isTileValue(Grid.get(grid, x, southCoord)) and 1 or 0

	local westCoord = x - 1
	local west = isTileValue(Grid.get(grid, westCoord, y)) and 1 or 0

	return north + (2 * east) + (4 * south) + (8 * west)
end

return getTileValue