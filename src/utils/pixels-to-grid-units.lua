local Math = require("utils.math")
local round = Math.round

-- returns coordinate values in tile units centered to the tile
local function pixelsToGridUnits(screenX, screenY, gridSize)
	local gridPixelX, gridPixelY = screenX, screenY
	local gridX, gridY =
		round(gridPixelX / gridSize),
		round(gridPixelY / gridSize)
	return gridX, gridY
end

return pixelsToGridUnits