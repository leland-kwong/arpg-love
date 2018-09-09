local Component = require 'modules.component'
local groups = require 'components.groups'
local Color = require 'modules.color'
local screenScale = require 'config.config'.scaleFactor
local tween = require 'modules.tween'
local msgBus = require 'components.msg-bus'
local moonshine = require 'modules.moonshine'

local vignette = love.graphics.newImage('built/images/vignette2.png')

local ScreenFx = {
  group = groups.hud,
  damageFlashOpacity = 0.3,
  opacity = 0,
}

-- flashes the screen red when the player gets hit

local function getScreenSize()
  return love.graphics.getWidth() / screenScale,
    love.graphics.getHeight() / screenScale
end

function ScreenFx.init(self)
  self.tween = tween.new(1.8, self, {opacity = 0}, tween.easing.outExpo)
  msgBus.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgBus.PLAYER_HIT_RECEIVED == msgType then
      self.opacity = self.damageFlashOpacity
      self.tween:reset()
      self.currentTween = self.tween
    end
  end)

  local screenWidth, screenHeight = getScreenSize()
  self.glowEffect = moonshine(screenWidth, screenHeight, moonshine.effects.vignette)
  self.glowEffect.vignette.radius = 0.1
  self.glowEffect.vignette.softness = 0.1
  self.glowEffect.vignette.opacity = 0.9
  self.glowEffect.vignette.color = {255,0,0}
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
    love.graphics.setColor(1,0,0,self.opacity)
    love.graphics.draw(
      vignette,
      0, 0
    )
  end
end

return Component.createFactory(ScreenFx)