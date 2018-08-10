-- position tools
local pixelsToGrid = require("utils.pixels-to-grid-units")
local gridToPixels = require("utils.grid-units-to-screen-units")
local memoize = require("utils.memoize")

local Position = {
  pixelsToGrid = pixelsToGrid,
  gridToPixels = gridToPixels
}

local mathAbs = math.abs

-- returns normalized values
Position.getDirection = memoize(function(x1, y1, x2, y2)
  local a = y2 - y1
  local b = x2 - x1
  local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
	return b/c, a/c
end)

function Position.normalizeVector(a, b)
	local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
	return a == 0 and 0 or a/c,
		b == 0 and 0 or b/c
end

return Position