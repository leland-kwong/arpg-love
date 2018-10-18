local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local AnimationFactory = require 'components.animation-factory'

local MenuButtons = {
  group = Component.groups.hud
}

function MenuButtons.init(self)
  local parent = self

  local buttons = {
    {
      actionName = 'home',
      sprite = 'gui-home-button',
      onClick = function()
        msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU)
      end
    },
    {
      actionName = 'settings',
      sprite = 'gui-home-button',
      onClick = function()
        msgBus.send(msgBus.SETTINGS_MENU_TOGGLE)
      end
    },
    {
      actionName = 'inventory',
      sprite = 'gui-home-button',
      onClick = function()
        msgBus.send(msgBus.INVENTORY_TOGGLE)
      end
    }
  }

  for index=1, #buttons do
    local b = buttons[index]
    local animation = AnimationFactory:newStaticSprite(b.sprite)
    local spriteWidth, spriteHeight = animation:getSourceSize()
    local drawIndex = index - 1
    local spacing = (drawIndex * spriteWidth) + (drawIndex * 5)
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
        love.graphics.draw(
          AnimationFactory.atlas,
          animation.sprite,
          self.x,
          self.y
        )
      end
    }):setParent(self)
  end
end

return Component.createFactory(MenuButtons)