-- status icon manager

local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

Component.create({
  id = 'statusIcons',
  init = function(self)
    Component.addToGroup(self, 'all')
    self.iconData = {}
  end,
  addIcon = function(self, icon, x, y)
    if (not icon) then
      return
    end
    table.insert(self.iconData, {icon, x, y})
  end,
  draw = function(self)
    for i=1, #self.iconData do
      local data = self.iconData[i]
      local icon, x, y = unpack(self.iconData[i])
      local animation = AnimationFactory:newStaticSprite(icon)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        x,
        y
      )
    end
    self.iconData = {}
  end,
  drawOrder = function()
    local drawOrders = require 'modules.draw-orders'
    return drawOrders.StatusIcons
  end
})