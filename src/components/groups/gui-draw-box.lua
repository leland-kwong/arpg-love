local Component = require 'modules.component'
local drawBox = require 'components.gui.utils.draw-box'

return function()
  for _,component in pairs(Component.groups.guiDrawBox.getAll()) do
    drawBox(component, component)
  end
end