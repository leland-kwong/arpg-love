local iterateGrid = require("utils.iterate-grid")

--local errorMsg = "invalid grid"
local function cloneGrid(grid, fillFunction, reverseX, reverseY)
	--assert(grid ~= nil, errorMsg)

	local newGrid = {}
	iterateGrid(grid, function(v, x, y)
		local shouldCreateRow = not newGrid[y]
		if shouldCreateRow then
			newGrid[y] = {}
		end
		if fillFunction then
			newGrid[y][x] = fillFunction(v, x, y)
		else
			newGrid[y][x] = v
		end
	end, reverseX, reverseY)
	return newGrid
end

return cloneGrid

--[[
local function cloneGrid(grid, fillFunction)
	return map(grid, function(row, y) 
		return map(row, function(colValue, x)
			if fillFunction then
				return fillFunction(colValue, x, y)
			end
			return colValue
		end)
	end)
end

return cloneGrid
]]--