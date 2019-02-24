-- Use collision detection to prevent a dialog box from going outside the screen

local function clamp(v, min, max)
  if v < min then
    return min
  end
  if v > max then
    return max
  end
  return v
end

local boxSchema = {
  width = 1,
  height = 1
}

local Box = {}

function Box.new(getEdges)
  local world = {}
  function world.move(box, x, y)
    local n, e, s, w, border = getEdges()
    return clamp(x, w + border, e - border - box.width),
      clamp(y, n + border, s - border - box.height)
  end
  return world
end

--[[
  boxTree [2D ARRAY] - a 2d-array of cells. Cells must be a table {width=[INT], height=[INT]}
]]
function Box.layout(boxTree, cellCallback)
  assert(type(boxTree) == 'table')
  assert(type(cellCallback) == 'function')

  local totalHeight = 0
  local maxWidth = 0
  local queue = {}
  for _,row in pairs(boxTree) do
    local rowHeight = 0
    local rowWidth = 0
    for _,cell in pairs(row) do
      local padding = cell.padding
      local padV = padding and padding[1] or 0
      local padH = padding and padding[2] or 0
      local x, y = rowWidth, totalHeight -- cache the values for the callback
      table.insert(queue, function(originX, originY)
        local actualX, actualY = x + originX, y + originY
        local boundingRect = {
          x = actualX,
          y = actualY,
          innerX = actualX + padH,
          innerY = actualY + padV,
          width = cell.width + (padH * 2),
          height = cell.height + (padV * 2)
        }
        cellCallback(
          cell,
          boundingRect,
          originX,
          originY,
          maxWidth,
          rowHeight
        )
      end)

      rowHeight = math.max(rowHeight, cell.height + padV * 2)
      rowWidth = rowWidth + cell.width + padH * 2
    end
    maxWidth = math.max(maxWidth, rowWidth)
    totalHeight = totalHeight + rowHeight
  end
  return {
    width = maxWidth,
    height = totalHeight,
    execAll = function(originX, originY)
      for i=1, #queue do
        queue[i](originX or 0, originY or 0)
      end
    end
  }
end

return Box