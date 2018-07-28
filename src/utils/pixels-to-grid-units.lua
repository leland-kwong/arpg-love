local math_utils = require("utils.math")

local ceil = math.ceil
-- returns coordinate values in tile units centered to the tile
local function pixelsToGridUnits(screenX, screenY)
	local round = math_utils.round
	return round(ceil(screenX / tile_size), 0), round(ceil(screenY / tile_size), 0)
end

return pixelsToGridUnits