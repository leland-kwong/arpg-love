local Component = require 'modules.component'
local GuiText = require 'components.gui.gui-text'
local groups = require 'components.groups'
local Color = require 'modules.color'
local Position = require 'utils.position'
local AnimationFactory = require 'components.animation-factory'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'hud')
    self.fillStencil = function()
      local components = Component.groups.hudStatusBarFancy.getAll()

      -- setup stencils
      for _,c in pairs(components) do

        local clamp = require 'utils.math'.clamp
        local fillPixelAmount = c.w * clamp(c.fillPercentage(), 0, 1)
        if c.fillDirection == 1 then
          love.graphics.rectangle('fill', c.x, c.y, fillPixelAmount, c.h)
        else
          local amountMissing = c.w - fillPixelAmount
          love.graphics.rectangle('fill', c.x + amountMissing, c.y, fillPixelAmount, c.h)
        end

      end
    end
  end,
  draw = function(self)
    local group = Component.groups.hudStatusBarFancy
    local components = group.getAll()

    local fillAnimation = AnimationFactory:newStaticSprite('gui-dashboard-status-bar-fancy')
    local spriteWidth = fillAnimation:getFullWidth()
    for _,c in pairs(components) do
      c.offsetX = c.fillDirection == -1 and spriteWidth or 0
    end
    love.graphics.stencil(self.fillStencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    for _,c in pairs(components) do
      love.graphics.setColor(c.color)
      love.graphics.draw(
        AnimationFactory.atlas,
        fillAnimation.sprite,
        c.x + c.fillDirection + c.offsetX,
        c.y + 1,
        0,
        c.fillDirection,
        1
      )
      Component.removeFromGroup(c, 'hudStatusBarFancy')
    end

    love.graphics.setStencilTest()
  end,
  drawOrder = function()
    return 50
  end
})

local StatusBarFancy = {
  group = groups.hud,
  color = {1,1,1},
  fillPercentage = function()
    return 0
  end,
  fillDirection = 1,
}

function StatusBarFancy.update(self)
  Component.addToGroup(self, 'hudStatusBarFancy')
end

return Component.createFactory(StatusBarFancy)