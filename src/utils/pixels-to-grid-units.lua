local math_utils = require("utils.math")

local ceil = math.ceil
local floor = math.floor

-- returns coordinate values in tile units centered to the tile
local function pixelsToGridUnits(screenX, screenY, gridSize)
	local gridPixelX, gridPixelY = screenX, screenY
	local gridX, gridY =
		floor(gridPixelX / gridSize),
		floor(gridPixelY / gridSize)
	return gridX, gridY
end

return pixelsToGridUnits