local M = {}

function M.boundingBox(x, y, w, h)
  love.graphics.rectangle(
    'line',
    x - w/2,
    y - h/2,
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