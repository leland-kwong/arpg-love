local Component = require 'modules.component'
local Row = require 'components.gui.block.row'
local layout = require 'components.gui.block.layout'
local objectUtils = require 'utils.object-utils'

local Block = {
  debug = false,
  group = Component.groups.gui,
  background = nil, -- background color of tooltip (includes padding)
  padding = 0, -- padding around tooltip content
  textOutline = false,
  rows = objectUtils.setReadOnly({})
}

Block.Row = Row

function Block.init(self)
  assert(type(self.rows) == 'table', '`rows` are required')
  self.fonts = {}
  self.textLayers = {}
end

function Block.update(self)
  local w, h = 0, 0
  for i=1, #self.rows do
    local row = self.rows[i]
    w = math.max(w, row.width)
    h = h + row.height + row.marginTop + row.marginBottom
  end
  self.width = w
  self.height = h
end

function Block.draw(self)
  if self.background then
    love.graphics.setColor(self.background)
    love.graphics.rectangle('fill', self.x, self.y, self.width + (self.padding * 2), self.height + (self.padding * 2))
  end

  layout(self.rows, self.x + self.padding, self.y + self.padding, function(_, _, col, colPosition)
    local xPos = colPosition.x
    local yPos = colPosition.y
    local font = self.fonts[col.font]
    if (not font) then
      font = type(col.font) == 'string' and
        love.graphics.newFont(col.font) or
        col.font
      self.fonts[col.font] = font
    end
    local layer = self.textLayers[col.font] or {}
    local textLayer = layer.textLayer
    if (not textLayer) then
      textLayer = love.graphics.newText(font)
      self.textLayers[font] = {
        textLayer = textLayer,
        shaderFontSize = {font:getHeight() * 2, font:getHeight() * 2}
      }
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

    local textXOffset = col.align == 'left' and col.padding or 0
    local textX, textY = xPos + textXOffset - borderOffset, yPos + col.padding - borderOffset
    if self.debug then
      love.graphics.setColor(1,1,0,1)
      love.graphics.rectangle('line', textX, textY, col.contentWidth, col.contentHeight)
    end
    textLayer:addf(col.content, col.contentWidth, col.align, math.floor(textX), math.floor(textY))
  end)

  love.graphics.setColor(1,1,1)
  local pixelOutlineShader = require 'modules.shaders.pixel-text-outline'
  for _,layer in pairs(self.textLayers) do
    if self.textOutline then
      pixelOutlineShader.attach(nil, nil, nil, layer.shaderFontSize)
    end
    love.graphics.draw(layer.textLayer)
    layer.textLayer:clear()
  end

  if self.textOutline then
    pixelOutlineShader.detach()
  end
end

return Component.createFactory(Block)