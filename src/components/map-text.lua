local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'

GuiText.create({
  group = 'all',
  id = 'MapText',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    local DrawOrders = require 'modules.draw-orders'
    return DrawOrders.MapText
  end,
})