local Component = require 'modules.component'
local groups = require 'components.groups'
local Color = require 'modules.color'
local screenScale = require 'config'.scaleFactor
local tween = require 'modules.tween'
local msgBus = require 'components.msg-bus'

local ScreenFx = {
  group = groups.gui,
  opacity = 0
}

-- flashes the screen red when the player gets hit

function ScreenFx.init(self)
  self.tween = tween.new(2, self, {opacity = 0}, tween.easing.outExpo)
  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.PLAYER_HIT == msgType then
      self.opacity = 0.7
      self.tween:reset()
      self.currentTween = self.tween
    end
  end)
end

-- we do a two-step tween to animate in then out
function ScreenFx.update(self, dt)
  if self.currentTween then
    local complete = self.currentTween:update(dt)
    if complete then
      self.currentTween = nil
    end
  end
end

function ScreenFx.draw(self)
  if self.currentTween then
    love.graphics.setColor(Color.rgba255(242, 51, 26, self.opacity))
    local thickness = 20
    love.graphics.setLineWidth(thickness)
    love.graphics.rectangle(
      'line',
      0, 0,
      love.graphics.getWidth() / screenScale,
      love.graphics.getHeight() / screenScale
    )
  end
end

return Component.createFactory(ScreenFx)