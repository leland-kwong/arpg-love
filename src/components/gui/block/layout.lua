local Vec2 = require 'modules.brinevector'

return function(rows, offsetX, offsetY, callback)
  local yPos = 0

  for i=1, #rows do
    local row = rows[i]
    local marginTop = row.marginTop
    local xPos = 0

    for j=1, #row.columns do
      local col = row.columns[j]
      local prevCol = row.columns[j - 1]
      col.position = Vec2(xPos + offsetX, yPos + offsetY + marginTop)
      callback(col)
      xPos = xPos + col.width
    end

    yPos = yPos + row.height + marginTop
  end
end