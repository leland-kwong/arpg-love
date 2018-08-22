-- position tools
local pixelsToGrid = require("utils.pixels-to-grid-units")
local gridToPixels = require("utils.grid-units-to-screen-units")
local memoize = require("utils.memoize")

local Position = {
  pixelsToGrid = pixelsToGrid,
  gridToPixels = gridToPixels
}

local mathAbs = math.abs
local sqrt, pow = math.sqrt, math.pow

-- returns normalized values
Position.getDirection = function(x1, y1, x2, y2)
  local a = y2 - y1
  local b = x2 - x1
  local c = sqrt(a*a + b*b)
  -- dividing by zero returns a NAN value, so we should coerce to zero
  return c == 0 and 0 or (b/c),
    c == 0 and 0 or (a/c)
end

-- returns coordinate offsets so that the item is centered to the parent with origin at north-west
function Position.boxCenterOffset(w, h, parentW, parentH)
  local x = (parentW - w) / 2
  local y = (parentH - h) / 2
  return x, y
end

return Position