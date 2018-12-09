local printGrid = require("utils.print-grid")

--uses 16-bit bitmasking to calculate tile value
local function calcTileValue(grid, x, y, fillValue)
	local northCoord = y - 1
	local north = (grid[northCoord] and grid[northCoord][x] == fillValue) and 1 or 0

	local eastCoord = x + 1
	local east = (grid[y][eastCoord] and grid[y][eastCoord] == fillValue) and 1 or 0

	local southCoord = y + 1
	local south = (grid[southCoord] and grid[southCoord][x] == fillValue) and 1 or 0

	local westCoord = x - 1
	local west = (grid[y][westCoord] and grid[y][westCoord] == fillValue) and 1 or 0

	return north + (2 * east) + (4 * south) + (8 * west)
end

--[[
[table] filterCallbacks
[function] filterCallbacks[gridValue]
--]]
local function iterateGrid(grid, callback, fillValue)
	for y=1,#grid do
		for x=1,#grid[1] do
			local gridValue = grid[y][x]
			if gridValue == fillValue then
				callback(calcTileValue(grid, x, y, fillValue), x, y)
			end
		end
	end
end

return {
	calcTileIndex = calcTileIndex,
	iterateGrid = iterateGrid
}