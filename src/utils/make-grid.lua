local FUNCTION = 'function'
local function isFunc(value)
	return type(value) == FUNCTION
end
	
local function makeGrid(w, h, fillValue)
	local grid = {}
	local fillTypeFunc = isFunc(fillValue)
	for y=1, h do
		grid[y] = {}
		for x=1, w do
			if fillTypeFunc then
				grid[y][x] = fillValue(x,y)
			elseif fillValue ~= nil then
				grid[y][x] = fillValue
			else
				grid[y][x] = 0
			end
		end
	end
	return grid
end

return makeGrid