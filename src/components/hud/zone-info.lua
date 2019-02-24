local Component = require 'modules.component'
local tween = require 'modules.tween'
local msgBus = require 'components.msg-bus'
local Position = require 'utils.position'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'
local Font = require 'components.font'

local ZoneInfo = {
  opacity = 1,
  duration = 2,
  zoneTitle = '',
  font = Font.secondaryLarge.font
}

local endState = {
  opacity = 0
}

function ZoneInfo.init(self)
  Component.addToGroup(self:getId(), 'hud', self)
  self.tween = tween.new(self.duration, self, endState, tween.easing.inExpo)
  self.textCanvas = love.graphics.newCanvas()
end

function ZoneInfo.update(self, dt)
  local complete = self.tween:update(dt)
  if complete then
    self:delete(true)
    return
  end
  local globalState = require 'main.global-state'
  self.zoneTitle = globalState.activeLevel.level
end

local textDrawDirections = {
  {-1, -1}, -- NW
  {0, -1}, -- N
  {1, -1}, -- NE
  {1, 0}, -- E
  {1, 2}, -- SE
  {0, 2}, -- S
  {-1, 2}, -- SW
  {-1, 0} -- W
}

function ZoneInfo.draw(self)
  local textW, textH = GuiText.getTextSize(self.zoneTitle, self.font)
  local scale = config.scale
  local winWidth, winHeight = love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
  local x, y = Position.boxCenterOffset(textW, textH, winWidth, winHeight)
  local finalY = y + 50
  local padding = 10
  -- love.graphics.setColor(1,1,1,0.15 * self.opacity)
  -- love.graphics.rectangle('fill', x - padding/2, finalY - padding/2, textW + padding, textH + padding)

  local tx, ty = 5, 5
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setBlendMode('alpha', 'alphamultiply')
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setCanvas(self.textCanvas)
  love.graphics.translate(tx, ty)
  love.graphics.setColor(0,0,0)
  love.graphics.setFont(self.font)
  local outlineWidth = 1
  for i=1, #textDrawDirections do
    local dir = textDrawDirections[i]
    local dx, dy = dir[1], dir[2]
    love.graphics.print(self.zoneTitle, dx * outlineWidth, dy * outlineWidth)
  end
  love.graphics.setColor(1,1,1)
  love.graphics.print(self.zoneTitle)
  love.graphics.pop()
  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setColor(1,1,1,self.opacity)
  love.graphics.draw(self.textCanvas, x - tx, finalY - ty)
end

function ZoneInfo.final(self)
  self.textCanvas:release()
end

return Component.createFactory(ZoneInfo)