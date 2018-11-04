local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local Color = require 'modules.color'
local Position = require 'utils.position'
local AnimationFactory = require 'components.animation-factory'

local StatusBarFancy = {
  group = groups.hud,
  color = {1,1,1},
  fillPercentage = function()
    return 0
  end,
  fillDirection = 1,
}

function StatusBarFancy.init(self)
  self.fillStencil = function()
    love.graphics.setColor(1,1,1)

    local clamp = require 'utils.math'.clamp
    local fillPixelAmount = self.w * clamp(self.fillPercentage(), 0, 1)
    if self.fillDirection == 1 then
      love.graphics.rectangle('fill', self.x, self.y, fillPixelAmount, self.h)
    else
      local amountMissing = self.w - fillPixelAmount
      love.graphics.rectangle('fill', self.x + amountMissing, self.y, fillPixelAmount, self.h)
    end
  end
end

function StatusBarFancy.draw(self)
  local outlineAnimation = AnimationFactory:newStaticSprite('gui-status-bar-outline')
  local fillSprite = AnimationFactory:newStaticSprite('gui-status-bar-fill-mask').sprite

  local spriteWidth = outlineAnimation:getWidth()
  local offsetX = self.fillDirection == -1 and spriteWidth or 0

  -- indicator outline
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(AnimationFactory.atlas, outlineAnimation.sprite, self.x + offsetX, self.y, 0, self.fillDirection, 1)

  love.graphics.stencil(self.fillStencil, 'replace', 1)
  love.graphics.setStencilTest('greater', 0)

  -- fill bars
  love.graphics.setColor(self.color)
  love.graphics.draw(
    AnimationFactory.atlas,
    fillSprite,
    self.x + self.fillDirection + offsetX,
    self.y + 1,
    0,
    self.fillDirection,
    1
  )

  love.graphics.setStencilTest()
end

return Component.createFactory(StatusBarFancy)