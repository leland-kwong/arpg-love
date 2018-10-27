--DEPRECATION: reverseX and reverseY are no longer supported

--[[
	Iterates a 2d grid assuming that rows and columns are arrays.
	This does not support grids that have missing rows and/or columns.
]]
local function iterateGrid(grid, callback, reverseX, reverseY)
	local lastRow = #grid + 1
	local lastCol = #grid[1] + 1
	local directionX = reverseX and -1 or 1
	local directionY = reverseY and -1 or 1
	local x = reverseX and (lastCol - 1) or 1;
	local initialX = x
	local y = reverseY and (lastRow - 1) or 1;

	while ((reverseY and y > 0) or (not reverseY and y < lastRow)) do
		while ((reverseX and x > 0) or (not reverseX and x < lastCol)) do
			local val = grid[y][x]

			callback(val, x, y)
			x = x + directionX
		end
		-- reset col index
		x = initialX
		y = y + directionY
	end
	return grid
end

return iterateGrid