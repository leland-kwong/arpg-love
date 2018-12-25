local dynamicRequire = require 'utils.dynamic-require'
local GuiText = require 'components.gui.gui-text'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Grid = require 'utils.grid'
local F = require 'utils.functional'
local Color = require 'modules.color'
local GuiList2 = dynamicRequire 'components.gui.menu-list-2'

local drawOrder = 100000

local TextLayer = GuiText.create({
  id = 'gui-list-text-layer',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return 4
  end
})

local items = {
  {
    text = 'lightning rod',
    sprite = 'gui-skill-tree_node_lightning'
  },
  {
    text = 'max energy',
    sprite = 'gui-skill-tree_node_max-energy'
  },
  {
    text = 'lightning rod',
    sprite = 'gui-skill-tree_node_lightning'
  },
  {
    text = 'lightning rod',
    sprite = 'gui-skill-tree_node_lightning'
  },
  {
    text = 'lightning rod',
    sprite = 'gui-skill-tree_node_lightning'
  },
  {
    text = 'lightning rod',
    sprite = 'gui-skill-tree_node_lightning'
  }
}
local itemWidth = 150

local AnimationFactory = require 'components.animation-factory'

local maxIconWidth = 0
local guiContainer_1 = F.map(items, function(item, index)
  local padding = 5
  return {
    Gui.create({
      id = 'guiNode_'..index,
      width = itemWidth + (padding * 2),
      height = 40,
      render = function(self)
        local x, y = self.x + padding, self.y + padding
        if self.hovered then
          love.graphics.setColor(1,1,0,0.3)
          love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
        end
        love.graphics.setColor(1,1,1)
        local textWidth, textHeight = TextLayer.getTextSize(item.text, TextLayer.font)
        local graphic = AnimationFactory:newStaticSprite(item.sprite)
        local spriteFullWidth, spriteFullHeight = graphic:getFullWidth(), graphic:getFullHeight()
        maxIconWidth = math.max(maxIconWidth, spriteFullWidth)
        local graphicOffsetX = -(maxIconWidth - spriteFullWidth)/2
        graphic:draw(
          x, y, 0, 1, 1, graphicOffsetX, 0
        )
        local textMargin = 5
        local textOffsetY = -3
        TextLayer:add(item.text, Color.WHITE, x + maxIconWidth + textMargin, y + graphic:getHeight()/2 + textOffsetY)
        self.height = math.max(spriteFullHeight, textHeight) + (padding * 2)
      end,
    })
  }
end)

local guiList = GuiList2.create({
  id = 'gui-list-test',
  x = 100,
  y = 100,
  height = 200,
  layoutItems = guiContainer_1,
  otherItems = {
    TextLayer
  },
  drawOrder = function()
    return drawOrder + 1
  end
})

Component.create({
  id = 'gui-list-test-init',
  init = function(self)
    Component.addToGroup(self, 'gui')
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end,
  draw = function()
    love.graphics.clear()
    love.graphics.rectangle('line', guiList.x, guiList.y, guiList.width, guiList.height)
  end,
  drawOrder = function()
    return drawOrder
  end
})
