--[[
  A component that emits a warning sound and prints out an error message to the player
]]

local Component = require 'modules.component'
local groups = require 'components.groups'
local GuiText = require 'components.gui.gui-text'
local msgBus = require 'components.msg-bus'
local tween = require 'modules.tween'
local Sound = require 'components.sound'
local config = require 'config.config'
local Position = require 'utils.position'

local ActionError = {
  group = groups.hud,
  textLayer = nil
}

function ActionError.init(self)
  self.listeners = {
    msgBus.on(msgBus.PLAYER_ACTION_ERROR, function(msgValue)
      if self:isDeleted() then
        return msgBus.CLEANUP
      end

      local Sound = require 'components.sound'
      love.audio.play(Sound.ACTION_ERROR)
      local textColor = {1,1,0,1}
      local subject = {
        message = msgValue,
        color = textColor
      }
      local endColor = {1,1,0,0} -- fade out
      self.errorMessage = subject
      self.errorMessageTween = tween.new(2.5, textColor, endColor, tween.easing.inExpo)

      return msgValue
    end)
  }
end

function ActionError.update(self, dt)
  if self.errorMessageTween then
    local complete = self.errorMessageTween:update(dt)
    if complete then
      self.errorMessage = nil
      self.errorMessageTween = nil
    end
  end
end

function ActionError.draw(self)
  if self.errorMessage then
    local errMsg = self.errorMessage
    local font = self.textLayer.font
    local textWidth, textHeight = GuiText.getTextSize(errMsg.message, font)
    local winWidth, winHeight = love.graphics.getWidth() / config.scale, love.graphics.getHeight() / config.scale
    local x = Position.boxCenterOffset(textWidth, textHeight, winWidth, winHeight)
    self.textLayer:add(errMsg.message, errMsg.color, x, winHeight - textHeight - 45)
  end
end

function ActionError.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(ActionError)