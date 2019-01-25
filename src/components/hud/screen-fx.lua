local Component = require 'modules.component'
local groups = require 'components.groups'
local Color = require 'modules.color'
local tween = require 'modules.tween'
local msgBus = require 'components.msg-bus'

local vignette = love.graphics.newImage('built/images/vignette2.png')

local ScreenFx = {
  group = groups.hud,
  damageFlashOpacity = 0.5,
  opacity = 0,
}

-- flashes the screen red when the player gets hit

function ScreenFx.init(self)
  self.tween = tween.new(1.8, self, {opacity = 0}, tween.easing.outExpo)

  msgBus.on(msgBus.PLAYER_HIT_RECEIVED, function(msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgValue <= 0 then
      return msgValue
    end

    self.opacity = self.damageFlashOpacity
    self.tween:reset()
    self.currentTween = self.tween

    return msgValue
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
    local camera = require 'components.camera'
    local cameraWidth = camera:getSize(true) * camera.scale
    local scale = cameraWidth / vignette:getPixelWidth()

    love.graphics.push()
    love.graphics.origin()
    love.graphics.scale(scale)

    love.graphics.setColor(1,0,0,self.opacity)
    love.graphics.draw(
      vignette,
      0, 0
    )

    love.graphics.pop()
  end
end

return Component.createFactory(ScreenFx)