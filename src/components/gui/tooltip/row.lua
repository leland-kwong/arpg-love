local functional = require 'utils.functional'
local GuiText = require 'components.gui.gui-text'
local font = require 'components.font'

local propTypes = {
  content = {}, -- love2d text object
  maxWidth = 100, -- content max width
  align = 'left',
  height = nil, -- if defined, forces the container to the specified height, otherwise defaults to auto-height
  font = nil, -- love2d font object
  fontSize = 16,
  padding = 0, -- container padding
  background = nil, -- background color
  border = nil,
  borderWidth = 0
}

local function setupAndValidateColumn(c)
  for k,v in pairs(propTypes) do
    c[k] = c[k] or v
    local isValid = type(c[k]) == type(v)
    assert(isValid, 'invalid property `'..k..'`')
  end
  return c
end

return function(columns)
  assert(type(columns) == 'table', 'row function must be an array of columns')
  local rowHeight = 0 -- highest column height
  local rowWidth = 0 -- total width of all columns
  local parsedColumns = functional.map(columns, function(col)
    col = setupAndValidateColumn(col)
    col.__index = col
    local textW, textH = GuiText.getTextSize(col.content, col.font, col.maxWidth)
    local heightAdjustment = math.max(0, (col.font:getLineHeight() - 0.8) * col.font:getHeight())
    local contentHeight = textH + (col.padding * 2) + (col.borderWidth * 2) - heightAdjustment
    local contentWidth = textW + (col.padding * 2) + (col.borderWidth * 2)
    rowHeight = math.max(rowHeight, contentHeight)
    rowWidth = rowWidth + contentWidth
    return setmetatable({
      height = contentHeight,
      width = contentWidth
    }, col)
  end)
  return {
    height = rowHeight,
    width = rowWidth,
    columns = parsedColumns
  }
end