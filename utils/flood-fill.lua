-- https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/
-- Note: mutates the grid
local function floodFill(grid, x, y, prevC, newC, callback) 
	local isOutOfBounds = y < 1 or x < 1 or y > #grid or x > #grid[1]
	if isOutOfBounds then
		return grid
	end
	if (grid[y][x] ~= prevC) then
		return grid
	end  
	-- update grid with new value
	grid[y][x] = newC

	if (callback and false == callback(x, y)) then
		return grid
	end

	-- recurse north, south, east, west
	floodFill(grid, x+1, y, prevC, newC, callback);
	floodFill(grid, x-1, y, prevC, newC, callback);
	floodFill(grid, x, y+1, prevC, newC, callback);
	floodFill(grid, x, y-1, prevC, newC, callback);  

	return grid
end

return floodFill