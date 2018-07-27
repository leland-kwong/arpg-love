-- translates grid coordinates to pixel coordinates
local function grid_to_screen(gridX, gridY)
	return pos_from_origin(gridX * tile_size, gridY * tile_size)
end

-- translates pixels on screen to grid without any translation
local function pixels_to_grid(px, py)
	return math_utils.round(px / tile_size), math_utils.round(py / tile_size)
end

local function game_object_grid_pos(go)
	local pos = go.get_position()	
	return screen_to_grid(pos.x, pos.y)
end

local function isOutOfBounds(grid, gridX, gridY)
	local rows = #grid
	local cols = #grid[1]

	return (gridX < 1) 
		or (gridY < 1) 
		or (gridX > cols) 
		or (gridY > rows)
end

return {
	grid_to_screen = grid_to_screen,
	screen_to_grid = screen_to_grid,
	pixels_to_grid = pixels_to_grid,
	game_object_grid_pos = game_object_grid_pos,
	isOutOfBounds = isOutOfBounds
}