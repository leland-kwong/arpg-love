local Component = require 'modules.component'
local Row = require 'components.gui.tooltip.row'

local Tooltip = {
  group = Component.groups.gui,
  background = nil, -- background color of tooltip (includes padding)
  padding = 0 -- padding around tooltip content
}

Tooltip.Row = Row

function Tooltip.init(self)
  assert(type(self.rows) == 'table', '`rows` are required')
  self.fonts = {}
  self.textLayers = {}
end

function Tooltip.update(self)
  local w, h = 0, 0
  for i=1, #self.rows do
    local row = self.rows[i]
    w = math.max(w, row.width)
    h = h + row.height
  end
  self.width = w
  self.height = h
end

function Tooltip.draw(self)
  local yPos = self.y

  if self.background then
    love.graphics.setColor(self.background)
    love.graphics.rectangle('fill', self.x - self.padding, self.y - self.padding, self.width + (self.padding * 2), self.height + (self.padding * 2))
  end

  for i=1, #self.rows do
    local row = self.rows[i]
    local xPos = self.x

    for j=1, #row.columns do
      local col = row.columns[j]

      local font = self.fonts[col.font]
      if (not font) then
        font = type(col.font) == 'string' and
          love.graphics.newFont(col.font) or
          col.font
        self.fonts[col.font] = font
      end
      local textLayer = self.textLayers[col.font]
      if (not textLayer) then
        textLayer = love.graphics.newText(font)
        self.textLayers[font] = textLayer
      end

      -- column background
      local bgWidth, bgHeight = col.width, col.height
      if col.background then
        love.graphics.setColor(col.background)
        love.graphics.rectangle('fill', xPos, yPos, bgWidth, bgHeight)
      end

      -- column border
      local borderOffset = -(0.5 * col.borderWidth)
      if col.border then
        love.graphics.setColor(col.border)
        love.graphics.setLineWidth(col.borderWidth)
        love.graphics.rectangle('line', xPos - borderOffset, yPos - borderOffset, bgWidth + (borderOffset * 2), bgHeight + (borderOffset * 2))
      end

      textLayer:addf(col.content, col.maxWidth, col.align, xPos + col.padding - borderOffset, yPos + col.padding - borderOffset)
      xPos = xPos + col.width
    end

    yPos = yPos + row.height
  end

  love.graphics.setColor(1,1,1)
  for _,textLayer in pairs(self.textLayers) do
    love.graphics.draw(textLayer)
  end
end

return Component.createFactory(Tooltip)