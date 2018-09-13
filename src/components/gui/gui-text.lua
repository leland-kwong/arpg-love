local Component = require 'modules.component'
local groups = require 'components.groups'
local font = require 'components.font'
local f = require 'utils.functional'

local textForMeasuringCache = {}
local function getTextForMeasuring(font)
  local textObject = textForMeasuringCache[font]
  if (not textObject) then
    textObject = love.graphics.newText(font, '')
    textForMeasuringCache[font] = textObject
  end
  return textObject
end

local GuiTextLayer = {
  group = groups.gui,
  font = font.secondary.font,
  outline = true,
  color = {1,1,1,1},

  -- statics
  getTextSize = function(text, font, wrapLimit, alignMode)
    local textForMeasuring = getTextForMeasuring(font)
    textForMeasuring:setf(
      text,
      wrapLimit or 99999,
      alignMode or 'left'
    )
    return textForMeasuring:getWidth(), textForMeasuring:getHeight()
  end
}

local w, h = 16, 16

function GuiTextLayer.add(self, text, color, x, y)
  self.tablePool[1] = color
  self.tablePool[2] = text
  self.textGraphic:add(self.tablePool, x, y)
end

function GuiTextLayer.addf(self, formattedText, wrapLimit, alignMode, x, y)
  self.textGraphic:addf(
    formattedText, -- [TABLE]
    wrapLimit,
    alignMode,
    x,
    y
  )
end

-- adds a text group via [love's text string format](https://love2d.org/wiki/Text:add)
function GuiTextLayer.addTextGroup(self, textGroup, x, y)
  self.textGraphic:add(textGroup, x, y)
  return self
end

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {0,0,0,1}
local shader = love.graphics.newShader(pixelOutlineShader)
shader:send('sprite_size', {w, h})
shader:send('outline_width', 2/w)
shader:send('outline_color', outlineColor)
shader:send('use_drawing_color', true)
shader:send('include_corners', true)

function GuiTextLayer.init(self)
  self.textGraphic = love.graphics.newText(self.font, '')
  self.tablePool = {}
end

function GuiTextLayer.getSize(self)
  return self.textGraphic:getWidth(), self.textGraphic:getHeight()
end

function GuiTextLayer.draw(self)
  if self.outline then
    love.graphics.setShader(shader)
  end

  shader:send('alpha', self.color[4])
  love.graphics.setColor(self.color)
  love.graphics.draw(self.textGraphic, x, y)
  self.textGraphic:clear()

  if self.outline then
    love.graphics.setShader()
  end
end

function GuiTextLayer.drawOrder()
  return 6
end

return Component.createFactory(GuiTextLayer)