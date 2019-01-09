local Grid = require 'utils.grid'

--[[
  Calculates all the rectangle coordinates using a 2-d array of cells.
  Each cell expects a width and height property

  Returns:
  {
    width = {},
    height = {}
    childRects = {}
  }
]]
return function(layoutGrid)
  local childrenProcessed = {}
  local rect = {
    childRects = {}
  }
  local posY = 0
  local maxWidth = 0
  local totalHeight = 0
  for rowOffset=1, #layoutGrid do
    local posX = 0
    local totalWidth = 0
    local rowHeight = 0
    local row = layoutGrid[rowOffset]
    for colOffset=1, #row do
      local col = row[colOffset]
      if childrenProcessed[col] then
        error('duplicate child in gui ['..rowOffset..','..colOffset..']')
      end
      childrenProcessed[col] = true
      Grid.set(rect.childRects, colOffset, rowOffset, {
        x = posX,
        y = posY
      })
      local colWidth = col.width or 0
      local colHeight = col.height or 0
      posX = posX + colWidth
      totalWidth = totalWidth + colWidth
      rowHeight = math.max(rowHeight, colHeight)
    end
    totalHeight = totalHeight + rowHeight
    maxWidth = math.max(maxWidth, totalWidth)
    posY = posY + rowHeight
  end
  rect.width = maxWidth
  rect.height = totalHeight
  return rect
end