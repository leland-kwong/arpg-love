local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local Color = require 'modules.color'
local Position = require 'utils.position'

local HealthIndicator = {
  group = groups.hud,
  color = {1,1,1},
  fillPercentage = function()
    return 0
  end,
  fillDirection = 1,
  hudTextLayer = nil
}

function HealthIndicator.draw(self)
  -- background
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

  -- fill amount
  love.graphics.setColor(self.color)
  local fillPixelAmount = self.w * self.fillPercentage()
  if self.fillDirection == 1 then
    love.graphics.rectangle('fill', self.x, self.y, fillPixelAmount, self.h)
  else
    local amountMissing = self.w - fillPixelAmount
    love.graphics.rectangle('fill', self.x + amountMissing, self.y, fillPixelAmount, self.h)
  end

  -- highlight
  love.graphics.setColor(1,1,1,0.1)
  love.graphics.rectangle('fill', self.x, self.y, self.w, self.h / 2)

  -- indicator outline
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
end

function HealthIndicator.drawOrder()
  return 1
end

return Component.createFactory(HealthIndicator)