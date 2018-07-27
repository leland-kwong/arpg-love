local origin = require("main.config.game-config").map_origin

function pos_from_origin(x, y)
	local new_x = origin.x + x
	local new_y = origin.y - y
	return new_x,new_y
end