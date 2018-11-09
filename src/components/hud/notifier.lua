local Component = require 'modules.component'
local groups = require 'components.groups'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local msgBus = require 'components.msg-bus'
local logger = require 'utils.logger'
local config = require 'config.config'
local AnimationFactory = require 'components.animation-factory'
local tween = require 'modules.tween'

local Notifier = {
  group = groups.hud,
  x = 0,
  y = 0,
  w = 0,
  color = {1,1,1,1},
  opacity = 0
}

function Notifier.init(self)
  self.guiText = GuiText.create({
    font = font.primary.font,
  }):setParent(self)
  self.eventLog = logger:new(4)
  self.listeners = {
    msgBus.on(msgBus.NOTIFIER_NEW_EVENT, function(msgValue)
      --[[ SCHEMA
        msgValue = {
          title = title,
          description = description,
          icon = icon
        }
      ]]
      msgValue.timestamp = os.date('%X')
      self.eventLog:add(msgValue)
      self.opacity = 1
      self.tween = tween.new(4, self, {opacity = 0}, tween.easing.inExpo)
      self:setDisabled(false)

      return msgValue
    end)
  }
end

function Notifier.update(self, dt)
  local complete = self.tween and self.tween:update(dt) or nil
  if complete then
    self.tween = nil
    self:setDisabled(true)
  else
    self.color[4] = self.opacity
  end
end

function Notifier.draw(self)
  love.graphics.setColor(0,0,0,0.2 * self.opacity)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  local padding = 5

  local iconSize = 30
  local iconRightMargin = 5
  local wrapWidth = self.w - padding - iconSize - iconRightMargin

  local startX, startY = self.x + padding, self.y + padding
  local totalHeight = 0
  local eventSpacing = 5
  local events = self.eventLog:get()
  for i=1, #events do
    local e = events[i]
    local posY = startY + totalHeight

    if e.icon then
      love.graphics.setColor(self.color)
      love.graphics.draw(
        AnimationFactory.atlas,
        AnimationFactory:newStaticSprite(e.icon).sprite,
        startX,
        posY
      )
    end

    local content = {
      Color.YELLOW, e.title..'\n',
      Color.MED_GRAY, e.timestamp..'\n'
    }

    for i=1, #(e.description or {}) do
      table.insert(content, e.description[i])
    end

    local contentStartX = startX + iconSize + iconRightMargin
    self.guiText:addf(
      content,
      wrapWidth,
      'left',
      contentStartX,
      posY
    )
    self.guiText:set('color', self.color)
    local contentWidth, contentHeight = GuiText.getTextSize(content, self.guiText.font, wrapWidth)
    totalHeight = totalHeight + contentHeight + eventSpacing
  end
end

function Notifier.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(Notifier)