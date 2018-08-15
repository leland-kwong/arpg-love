local Component = require 'modules.component'local groups = require 'components.groups'
local font = require 'components.font'
local f = require 'utils.functional'

local GuiTextLayer = {
  group = groups.gui,
  font = font.secondary.font,
  outline = true
}

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {0,0,0,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local w, h = 16, 16
shader:send('sprite_size', {w, h})
shader:send('outline_width', 2/16)
shader:send('outline_color', outlineColor)
shader:send('use_drawing_color', true)
shader:send('include_corners', true)

function GuiTextLayer.add(self, text, color, x, y)
  self.tablePool[1] = color
  self.tablePool[2] = text
  self.textGraphic:add(self.tablePool, x, y)
end

function GuiTextLayer.init(self)
  self.textGraphic = love.graphics.newText(self.font, '')
  self.tablePool = {}
end

function GuiTextLayer.draw(self)
  love.graphics.setShader(shader)
  love.graphics.setColor(1,1,1)
  love.graphics.draw(self.textGraphic, x, y)
  self.textGraphic:clear()
  love.graphics.setShader()
end

function GuiTextLayer.drawOrder()
  return 4
end

return Component.createFactory(GuiTextLayer)