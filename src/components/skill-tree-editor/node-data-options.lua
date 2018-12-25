local Component = require 'modules.component'
local MenuList = require 'components.menu-list'
local F = require 'utils.functional'
local config = require 'config.config'
local GuiText = require 'components.gui.gui-text'
local Gui = require 'components.gui.gui'
local GuiList2 = require 'components.gui.menu-list-2'
local Color = require 'modules.color'

local TextLayer = GuiText.create({
  id = 'gui-list-text-layer',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return 4
  end
})
local itemWidth = 200
local AnimationFactory = require 'components.animation-factory'

return Component.createFactory({
  options = {},
  onSelect = function(name, value)
  end,
  x = 5,
  y = 5,
  height = 250,
  init = function(self)
    Component.addToGroup(self, 'gui')
    local parent = self
    local maxIconWidth = 0
    local guiContainer_1 = F.map(F.keys(self.options), function(key, index)
      local o = self.options[key]
      local padding = 5
      return {
        Gui.create({
          id = parent:getId()..index,
          width = itemWidth + (padding * 2),
          height = 1,
          onClick = function()
            parent.onSelect(o.name, key)
          end,
          render = function(self)
            local x, y = self.x + padding, self.y + padding
            if self.hovered then
              love.graphics.setColor(1,1,0,0.3)
              love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
            end
            love.graphics.setColor(1,1,1)
            local textWidth, textHeight = TextLayer.getTextSize(o.name, TextLayer.font)
            local graphic = AnimationFactory:newStaticSprite(o.image)
            local spriteFullWidth, spriteFullHeight = graphic:getFullWidth(), graphic:getFullHeight()
            maxIconWidth = math.max(maxIconWidth, spriteFullWidth)
            local graphicOffsetX = -(maxIconWidth - spriteFullWidth)/2
            graphic:draw(
              x, y, 0, 1, 1, graphicOffsetX, 0
            )
            local textMargin = 5
            local textOffsetY = -3
            TextLayer:add(o.name, Color.WHITE, x + maxIconWidth + textMargin, y + graphic:getHeight()/2 + textOffsetY)
            self.height = math.max(spriteFullHeight, textHeight) + (padding * 2)
          end,
        })
      }
    end)

    self.guiList = GuiList2.create({
      x = parent.x,
      y = parent.y,
      height = parent.height,
      layoutItems = guiContainer_1,
      otherItems = {
        TextLayer
      },
      drawOrder = function()
        return parent:drawOrder() + 1
      end
    }):setParent(parent)
  end,

  draw = function(self)
    local drawBox = require 'components.gui.utils.draw-box'
    drawBox(self.guiList)
  end,

  drawOrder = function()
    return 20
  end
})