local function toScreen(gridX, gridY, cellSize)
	return gridX * cellSize, gridY * cellSize
end

return toScreen