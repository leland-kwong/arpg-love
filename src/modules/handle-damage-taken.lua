local Component = require 'modules.component'
local Color = require 'modules.color'
local PopupTextController = require 'components.popup-text'
local Sound = require 'components.sound'
local msgBus = require 'components.msg-bus'

local popupText = PopupTextController.create({
  font = require 'components.font'.secondary.font
})
local popupTextCritMultiplier = PopupTextController.create({
  font = require 'components.font'.secondary.font,
  color = Color.YELLOW
})

local function hitAnimation()
  local frame = 0
  local animationLength = 4
  while frame < animationLength do
    frame = frame + 1
    coroutine.yield(false)
  end
  coroutine.yield(true)
end

local function onDamageTaken(self, actualDamage, actualNonCritDamage, criticalMultiplier, actualLightningDamage)
  self.health = self.health - actualDamage
  self.isDestroyed = self.health <= 0

  if (actualDamage == 0) then
    return
  end

  Component.addToGroup(self:getId(), 'all', self)

  local getTextSize = require 'components.gui.gui-text'.getTextSize
  local offsetCenter = -getTextSize(actualDamage, popupText.font) / 2
  local isCriticalHit = criticalMultiplier > 0
  if (isCriticalHit) then
    local critText = criticalMultiplier..'x '
    popupTextCritMultiplier:new(
      critText,
      self.x + offsetCenter - getTextSize(critText, popupText.font),
      self.y - self.h
    )
  end
  popupText:new(
    actualDamage,
    self.x + offsetCenter,
    self.y - self.h
  )
  self.hitAnimation = coroutine.wrap(hitAnimation)

  if actualLightningDamage > 0 then
    love.audio.stop(Sound.ELECTRIC_SHOCK_SHORT)
    love.audio.play(Sound.ELECTRIC_SHOCK_SHORT)
  end

  Sound.ENEMY_IMPACT:setFilter {
    type = 'lowpass',
    volume = .5,
  }
  love.audio.stop(Sound.ENEMY_IMPACT)
  love.audio.play(Sound.ENEMY_IMPACT)
end

return onDamageTaken