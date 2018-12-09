local Math = require("utils.math")
local round = Math.round

-- returns coordinate values in tile units centered to the tile
local function pixelsToGridUnits(screenX, screenY, gridSize)
	local gridX, gridY =
		math.floor(screenX / gridSize),
		math.floor(screenY / gridSize)
	return gridX, gridY
end

return pixelsToGridUnits