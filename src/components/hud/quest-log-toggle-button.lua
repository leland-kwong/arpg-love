local Gui = require 'components.gui.gui'
local O = require 'utils.object-utils'
local AnimationFactory = require 'components.animation-factory'

return function(options)
  local normalIcon = AnimationFactory:newStaticSprite('gui-quest-log-button')
  local hoverIcon = AnimationFactory:newStaticSprite('gui-quest-log-button-hover')
  return Gui.create(
    O.extend({
      width = normalIcon:getWidth(),
      height = normalIcon:getHeight(),
      onClick = function()
        local msgBus = require 'components.msg-bus'
        msgBus.send('QUEST_LOG_TOGGLE')
      end,
      render = function(self)
        love.graphics.setColor(1,1,1)
        local icon = self.hovered and hoverIcon or normalIcon
        icon:draw(self.x, self.y)
      end
    }, options)
  )
end