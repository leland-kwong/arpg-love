local floor = math.floor

-- returns coordinate values in tile units centered to the tile
local function pixelsToGridUnits(screenX, screenY, gridSize)
	local gridX, gridY =
		floor(screenX / gridSize),
		floor(screenY / gridSize)
	return gridX, gridY
end

return pixelsToGridUnits