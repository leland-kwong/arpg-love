local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local Position = require 'utils.position'

local HealthIndicator = {
  group = groups.gui,
  health = 0
}

local hudTextLayer = GuiText.create()

function HealthIndicator.init(self)
  self.health = self.rootStore:get().health
  self.maxHealth = self.rootStore:get().maxHealth
  msgBus.subscribe(function(msgType, msgValue)
    if self._deleted then
      return msgBus.CLEANUP
    end

    if msgBus.PLAYER_HIT == msgType then
      self.rootStore:set('health', function(state)
        return state.health - msgValue.damage
      end)
      self.health = self.rootStore:get().health
    end
  end)
end

function HealthIndicator.draw(self)
  local healthText = self.health .. '/' .. self.maxHealth
  local textW, textH = hudTextLayer.getTextSize(healthText, hudTextLayer.font)
  local textOffX, textOffY = Position.boxCenterOffset(textW, textH, self.w, self.h)
  local textX, textY = self.x + textOffX, self.y + textOffY
  hudTextLayer:add(healthText, Color.WHITE, textX, textY)

  -- background
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

  -- health remaining
  local r, g, b = 0.88, 0.086, 0.06
  local healthIndicatorWidth = self.health / self.maxHealth * self.w
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle('fill', self.x, self.y, healthIndicatorWidth, self.h)

  -- indicator outline
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

function HealthIndicator.drawOrder()
  return 1
end

return Component.createFactory(HealthIndicator)