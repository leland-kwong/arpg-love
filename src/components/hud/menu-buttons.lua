local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local AnimationFactory = require 'components.animation-factory'
local font = require 'components.font'
local GuiText = require 'components.gui.gui-text'

local MenuButtons = {
  group = Component.groups.hud
}

local tooltipText = GuiText.create({
  font = font.primary.font
})

local function showTooltip(x, y, text)
  local textWidth, textHeight = GuiText.getTextSize(text, tooltipText.font)
  local padding = 4
  local Color = require 'modules.color'
  local actualY = y - textHeight - (padding * 2)
  love.graphics.setColor(Color.DARK_GRAY)
  love.graphics.rectangle('fill', x, actualY, textWidth + (padding * 2), textHeight + padding)
  tooltipText:add(text, Color.WHITE, x + padding, actualY + padding)
end

function MenuButtons.init(self)
  local parent = self

  local buttons = {
    {
      displayValue = 'Main Menu (esc)',
      normalAni = AnimationFactory:newStaticSprite('gui-home-button'),
      hoverAni = AnimationFactory:newStaticSprite('gui-home-button--hover'),
      onClick = function()
        msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU)
      end
    },
    {
      displayValue = 'Inventory (i)',
      normalAni = AnimationFactory:newStaticSprite('gui-inventory-button'),
      hoverAni = AnimationFactory:newStaticSprite('gui-inventory-button--hover'),
      onClick = function()
        msgBus.send(msgBus.INVENTORY_TOGGLE)
      end
    }
  }

  for index=1, #buttons do
    local b = buttons[index]
    local spriteWidth, spriteHeight = b.normalAni:getSourceSize()
    local drawIndex = index - 1
    local spacing = (drawIndex * spriteWidth) + (drawIndex * 2)
    Gui.create({
      x = parent.x + spacing,
      y = parent.y,
      group = Component.groups.hud,
      type = Gui.types.BUTTON,
      onClick = b.onClick,
      onUpdate = function(self)
        self.w, self.h = spriteWidth, spriteHeight
      end,
      draw = function(self)
        love.graphics.setColor(1,1,1)
        local animation = self.hovered and b.hoverAni or b.normalAni
        love.graphics.draw(
          AnimationFactory.atlas,
          animation.sprite,
          self.x,
          self.y
        )

        if self.hovered then
          showTooltip(self.x, self.y, b.displayValue)
        end
      end
    }):setParent(self)
  end
end

return Component.createFactory(MenuButtons)