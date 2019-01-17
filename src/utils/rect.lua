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
      local pLeft = (col.paddingLeft or 0)
      local pRight = (col.paddingRight or 0)
      local pTop = (col.paddingTop or 0)
      local pBot = (col.paddingBottom or 0)
      local colWidth = (col.width or 0) + pLeft + pRight
      local colHeight = (col.height or 0) + pTop + pBot
      Grid.set(rect.childRects, colOffset, rowOffset, {
        x = posX + pLeft,
        y = posY + pTop,
        width = colWidth,
        height = colHeight,
        colData = col
      })
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