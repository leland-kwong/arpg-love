local Color = require 'modules.color'
local M = {}

-- creates a bounding box centered to point x,y
function M.boundingBox(mode, x, y, w, h)
  local ox, oy = -w/2, -h/2
  love.graphics.rectangle(
    mode,
    x + ox,
    y + oy,
    w,
    h
  )
  love.graphics.circle(
    'fill',
    x,
    y,
    2
  )
end

return M