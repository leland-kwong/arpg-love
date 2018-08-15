local Component = require 'modules.component'local groups = require 'components.groups'
local font = require 'components.font'
local f = require 'utils.functional'

local GuiTextLayer = {
  group = groups.gui,
  font = font.secondary.font
}

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
  love.graphics.setColor(1,1,1)
  love.graphics.draw(self.textGraphic, x, y)
  self.textGraphic:clear()
end

function GuiTextLayer.drawOrder()
  return 4
end

return Component.createFactory(GuiTextLayer)