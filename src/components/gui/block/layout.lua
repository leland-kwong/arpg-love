--[[
  gui layout engine that invokes a callback for each column in each row
]]

local Vec2 = require 'modules.brinevector'

return function(rows, offsetX, offsetY, callback)
  local yPos = offsetY

  for i=1, #rows do
    local row = rows[i]
    local marginTop = row.marginTop
    local marginBottom = row.marginBottom
    local xPos = offsetX
    local rowPos = Vec2(xPos, yPos)

    for j=1, #row.columns do
      local col = row.columns[j]
      local prevCol = row.columns[j - 1]
      local colPosition = Vec2(xPos, yPos + marginTop)
      callback(row, rowPos, col, colPosition, i, j)
      xPos = xPos + col.width
    end

    yPos = yPos + row.height + marginTop + marginBottom
  end
end