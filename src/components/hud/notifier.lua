local Component = require 'modules.component'
local groups = require 'components.groups'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local font = require 'components.font'
local msgBus = require 'components.msg-bus'
local logger = require 'utils.logger'
local config = require 'config.config'
local AnimationFactory = require 'components.animation-factory'

local Notifier = {
  group = groups.hud,
  x = 0,
  y = 0,
  w = 0
}

function Notifier.init(self)
  self.guiText = GuiText.create({
    font = font.primary.font,
  })
  self.eventLog = logger:new(4)
  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.NOTIFIER_NEW_EVENT == msgType then
      --[[ SCHEMA
        msgValue = {
          title = title,
          description = description,
          icon = icon
        }
      ]]
      msgValue.timestamp = os.time()
      self.eventLog:add(msgValue)
    end
  end)
end

function Notifier.draw(self)
  love.graphics.setColor(0,0,0,0.2)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
  local padding = 5

  local wrapWidth = self.w - padding

  local startX, startY = self.x + padding, self.y + padding
  local totalHeight = 0
  local eventSpacing = 10
  local events = self.eventLog:get()
  for i=1, #events do
    local e = events[i]
    local titleWidth, titleHeight = GuiText.getTextSize(e.title, self.guiText.font)
    local titleMargin = titleHeight * 0.5
    titleHeight = titleHeight + titleMargin
    local descriptionWidth, descriptionHeight = GuiText.getTextSize(
      e.description, self.guiText.font
    )
    local posY = startY + totalHeight
    local iconSize = 30

    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      AnimationFactory:newStaticSprite(e.icon).sprite,
      startX,
      posY
    )

    local contentStartX = startX + iconSize + 5
    self.guiText:add(e.title, Color.YELLOW, contentStartX, posY)
    self.guiText:addf(
      e.description,
      wrapWidth,
      'left',
      contentStartX,
      posY + titleHeight
    )
    totalHeight = totalHeight + titleHeight + descriptionHeight + eventSpacing
  end
end

return Component.createFactory(Notifier)