local dynamicRequire = require 'utils.dynamic-require'
local GuiList = dynamicRequire 'components.gui.gui-list'
local GuiText = require 'components.gui.gui-text'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Grid = require 'utils.grid'
local F = require 'utils.functional'
local Color = require 'modules.color'

local drawOrder = 100000

local TextLayer = GuiText.create({
  id = 'gui-list-text-layer',
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return 4
  end
})

local guiList = GuiList.create({
  id = 'gui-list-test',
  x = 100,
  y = 100,
  height = 200,
  childNodes = {},
  drawOrder = function()
    return drawOrder + 1
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
      draw = function(self)
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

local function getRect(layoutGrid)
  local childrenProcessed = {}
  local rect = {
    childRects = {}
  }
  local posY = 0
  local maxWidth = 0
  local totalHeight = 0
  for rowOffset=1, #layoutGrid do
    local posX = 0
    local totalWidth = 0
    local rowHeight = 0
    local row = layoutGrid[rowOffset]
    for colOffset=1, #row do
      local col = row[colOffset]
      if childrenProcessed[col] then
        error('duplicate child in gui ['..rowOffset..','..colOffset..']')
      end
      childrenProcessed[col] = true
      Grid.set(rect.childRects, colOffset, rowOffset, {
        x = posX,
        y = posY
      })
      posX = posX + col.width
      totalWidth = totalWidth + col.width
      rowHeight = math.max(rowHeight, col.height)
    end
    totalHeight = totalHeight + rowHeight
    maxWidth = math.max(maxWidth, totalWidth)
    posY = posY + rowHeight
  end
  rect.width = maxWidth
  rect.height = totalHeight
  return rect
end

Component.create({
  id = 'gui-list-test-component',
  init = function(self)
    Component.addToGroup(self, 'gui')
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end,
  guiItems = guiContainer_1,
  update = function(self, dt)
    local childNodes = {}
    local newRect = getRect(self.guiItems)
    Grid.forEach(newRect.childRects, function(rect, x, y)
      local guiNode = Grid.get(self.guiItems, x, y)
      guiNode.x = guiList.x + rect.x
      guiNode.y = guiList.y + rect.y + guiList.scrollTop
      table.insert(childNodes, guiNode)
    end)

    guiList.contentHeight = newRect.height
    guiList.contentWidth = newRect.width
    guiList.width = newRect.width
    table.insert(childNodes, TextLayer)
    guiList.childNodes = childNodes
  end,
  draw = function()
    love.graphics.clear()
    love.graphics.rectangle('line', guiList.x, guiList.y, guiList.width, guiList.height)
  end,
  drawOrder = function()
    return drawOrder
  end
})