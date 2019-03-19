local toGrid = require("utils.pixels-to-grid-units")
local toScreen = require("utils.grid-units-to-screen-units")

-- returns a point that is the center of a tile
local function toTile(screenX, screenY)
	local tileCenterDist = tile_size / 2
	local x, y = toScreen(toGrid(screenX, screenY))
	return x - tileCenterDist, y - tileCenterDist
end

return toTile