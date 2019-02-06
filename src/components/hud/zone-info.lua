local Component = require 'modules.component'
local tween = require 'modules.tween'
local msgBus = require 'components.msg-bus'
local Position = require 'utils.position'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'

local ZoneInfo = {
  opacity = 1,
  duration = 2,
  zoneTitle = ''
}

local endState = {
  opacity = 0
}

function ZoneInfo.init(self)
  Component.addToGroup(self:getId(), 'hud', self)
  self.tween = tween.new(self.duration, self, endState, tween.easing.inExpo)
  self.textLayer = GuiText.create({
    group = Component.groups.hud,
    font = require 'components.font'.secondaryLarge.font
  })
  Component.addToGroup(self.textLayer, 'gameWorld')
end

function ZoneInfo.update(self, dt)
  local complete = self.tween:update(dt)
  if complete then
    self:delete(true)
    return
  end
  local globalState = require 'main.global-state'
  self.zoneTitle = globalState.sceneTitle
end

function ZoneInfo.draw(self)
  local font = self.textLayer.font
  local oLineHeight = font:getLineHeight()
  font:setLineHeight(1)
  local textW, textH = GuiText.getTextSize(self.zoneTitle, self.textLayer.font)
  font:setLineHeight(oLineHeight)
  local scale = config.scale
  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local x, y = Position.boxCenterOffset(textW, textH, winWidth, winHeight)
  local finalY = y - 60
  local padding = 10
  love.graphics.setColor(1,1,1,0.15 * self.opacity)
  love.graphics.rectangle('fill', x - padding/2, finalY - padding/2, textW + padding, textH + padding)

  local textColor = {1,1,1,self.opacity}
  self.textLayer:add(self.zoneTitle, textColor, x, finalY)
  self.textLayer.color = textColor
end

return Component.createFactory(ZoneInfo)