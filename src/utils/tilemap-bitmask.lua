local printGrid = require("utils.print-grid")
local Global = require("main.global")

--uses 16-bit bitmasking to calculate tile value
local function calcTileValue(grid, x, y)
	local northCoord = y - 1
	local north = (grid[northCoord] and grid[northCoord][x] > 0) and 1 or 0

	local eastCoord = x + 1
	local east = (grid[y][eastCoord] and grid[y][eastCoord] > 0) and 1 or 0

	local southCoord = y + 1
	local south = (grid[southCoord] and grid[southCoord][x] > 0) and 1 or 0

	local westCoord = x - 1
	local west = (grid[y][westCoord] and grid[y][westCoord] > 0) and 1 or 0

	return north + (2 * east) + (4 * south) + (8 * west)
end

--[[
[table] filterCallbacks
[function] filterCallbacks[gridValue]
--]]
local function iterateGrid(grid, filterCallbacks)
	for y=1,#grid do
		for x=1,#grid[1] do
			local gridValue = grid[y][x]
			local callback = filterCallbacks[gridValue]			
			if callback then
				callback(calcTileValue(grid, x, y), x, y)
			end
		end
	end
end

--[[
if Global.isDevelopment then
	local grid = {
		{0,0,0,0,0,0},
		{0,0,1,1,0,0},
		{0,0,1,1,1,0},
		{0,0,0,1,0,0},
		{0,0,0,0,0,0},
	}

	iterateGrid(grid, function(v, x, y) 
		grid[y][x] = v
	end)
	printGrid(grid, '', function(v) 
		if v > 0 and v < 10 then
			return "'0"..v.."'"
		elseif v > 10 then
			return "'"..v.."'"
		end
		return "  "
	end)
end
]]--

return {
	calcTileIndex = calcTileIndex,
	iterateGrid = iterateGrid
}