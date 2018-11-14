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
    },
    {
      displayValue = 'Skill Tree (o)',
      normalAni = AnimationFactory:newStaticSprite('gui-skill-tree-button'),
      hoverAni = AnimationFactory:newStaticSprite('gui-skill-tree-button--hover'),
      badge = function()
        local PlayerPassiveTree = require 'components.player.passive-tree'
        local unusedSkillPoints = PlayerPassiveTree.getUnusedSkillPoints()
        return unusedSkillPoints
      end,
      onClick = function()
        msgBus.send(msgBus.PASSIVE_SKILLS_TREE_TOGGLE)
      end
    },
  }

  for index=1, #buttons do
    local b = buttons[index]
    local spriteWidth, spriteHeight = b.normalAni:getSourceSize()
    local drawIndex = index - 1
    local margin = 2
    local spacing = (drawIndex * spriteWidth) + (drawIndex * margin)
    Gui.create({
      x = parent.x + spacing,
      y = parent.y,
      group = Component.groups.hud,
      type = Gui.types.BUTTON,
      onClick = b.onClick,
      onUpdate = function(self, dt)
        self.w, self.h = spriteWidth, spriteHeight
        self.clock = (self.clock or 0) + (dt * 3)
      end,
      draw = function(self)
        local Color = require 'modules.color'
        local highlightColor = nil
        local badgeValue = b.badge and b.badge() or 0
        badgeValue = (badgeValue > 0) and badgeValue or nil
        if badgeValue and (badgeValue > 9) then
          badgeValue = '9+'
        end
        local showBadge = badgeValue ~= nil
        love.graphics.setColor(1,1,1)
        local yPos = showBadge and (self.y + math.sin(self.clock) * -1) or self.y

        if showBadge then
          local hudTextSmallLayer = Component.get('hudTextSmallLayer')
          local x, y = self.x + spriteWidth - 3, yPos
          hudTextSmallLayer:add(
            badgeValue,
            Color.WHITE,
            x,
            y
          )
          local drawBox = require 'components.gui.utils.draw-box'
          highlightColor = {Color.multiplyAlpha(Color.PURPLE, math.sin(self.clock))}
          drawBox({
            x = self.x + 1,
            y = yPos + 1,
            width = self.w,
            height = self.h
          }, {
            borderWidth = 2,
            borderColor = highlightColor
          })
        end

        local animation = self.hovered and b.hoverAni or b.normalAni
        love.graphics.draw(
          AnimationFactory.atlas,
          animation.sprite,
          self.x,
          yPos
        )

        if highlightColor then
          love.graphics.setColor(highlightColor)
          love.graphics.draw(
            AnimationFactory.atlas,
            animation.sprite,
            self.x,
            yPos
          )
        end

        if self.hovered then
          showTooltip(self.x, yPos, b.displayValue)
        end
      end
    }):setParent(self)
  end
end

return Component.createFactory(MenuButtons)