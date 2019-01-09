local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'

Component.create({
  id = 'MapText',
  init = function(self)
    Component.addToGroup(self, 'firstLayer')
    self.text = GuiText.create({
      group = 'all',
      font = require 'components.font'.primary.font,
      drawOrder = function()
        local DrawOrders = require 'modules.draw-orders'
        return DrawOrders.MapText
      end,
    }):setParent(self)
  end,
  update = function(self)
    local components = Component.groups.mapText.getAll()
    for _,c in pairs(components) do
      local x = c.x
      local textWidth, textHeight = GuiText.getTextSize(c.text, self.text.font, wrapLimit)
      local wrapLimit = c.wrapLimit or textWidth
      if c.align == 'center' then
        x = c.x - textWidth/2
      elseif c.align == 'right' then
        x = c.x - textWidth
      end
      self.text:addf(c.text, wrapLimit, c.align or 'left', x, c.y)
    end
    Component.clearGroup('mapText')
  end,
})