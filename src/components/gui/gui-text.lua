local Component = require 'modules.component'
local groups = require 'components.groups'
local font = require 'components.font'
local f = require 'utils.functional'

local textForMeasuringCache = {}
local function getTextForMeasuring(font)
  local textObject = textForMeasuringCache[font]
  if not fromCache then
    textObject = love.graphics.newText(font, '')
    textForMeasuringCache[font] = textObject
  end
  return textObject
end

local GuiTextLayer = {
  group = groups.gui,
  font = font.secondary.font,
  outline = true,

  -- statics
  getTextSize = function(text, font)
    local textForMeasuring = getTextForMeasuring(font)
    textForMeasuring:set(text)
    return textForMeasuring:getWidth(), textForMeasuring:getHeight()
  end
}

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {0,0,0,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local w, h = 16, 16

function GuiTextLayer.add(self, text, color, x, y)
  self.tablePool[1] = color
  self.tablePool[2] = text
  self.textGraphic:add(self.tablePool, x, y)
end

-- adds a text group via [love's text string format](https://love2d.org/wiki/Text:add)
function GuiTextLayer.addTextGroup(self, textGroup, x, y)
  self.textGraphic:add(textGroup, x, y)
  return self
end

function GuiTextLayer.init(self)
  shader:send('sprite_size', {w, h})
  shader:send('outline_width', 2/w)
  shader:send('outline_color', outlineColor)
  shader:send('use_drawing_color', true)
  shader:send('include_corners', true)
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

  love.graphics.setColor(1,1,1)
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