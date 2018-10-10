local Gui = require 'components.gui.gui'
local GuiBlock = require 'components.gui.block'
local guiBlockLayout = require 'components.gui.block.layout'
local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local f = require 'utils.functional'
local font = require 'components.font'
local Color = require 'modules.color'
local Position = require 'utils.position'

local MenuList = {
  x = 0,
  y = 0,
  group = groups.gui,
  -- table of menu options
  options = {
    {
      name = '', -- [STRING]
      value = {} -- [ANY]
    }
  },
  onSelect = nil
}

function MenuList.init(self)
  assert(type(self.onSelect) == 'function', 'onSelect method required')

  local parent = self
  local itemFont = font.primary.font

  local onSelect = self.onSelect
  local menuX = self.x
  local menuY = self.y
  local startYOffset = 10
  local menuWidth = 300

  local rows = f.map(self.options, function(options)
    local name = options.name
    local content = type(name) == 'table' and name or {Color.WHITE, name}
    return GuiBlock.Row({
      {
        content = content,
        width = menuWidth,
        padding = 10,
        font = itemFont,
        fontSize = itemFont:getHeight()
      }
    })
  end)
  GuiBlock.create({
    x = self.x,
    y = self.y + 30,
    rows = rows,
    drawOrder = function()
      return parent:drawOrder() + 1
    end,
    textOutline = true
  }):setParent(self)

  -- menu option gui nodes
  guiBlockLayout(rows, self.x, self.y + 30, function(row, rowPosition, _, _, rowIndex)
    local option = self.options[rowIndex]
    local name = option.name
    local optionValue = option.value
    local textW, textH = GuiText.getTextSize(name, itemFont)
    local lineHeight = 1.8
    local h = (textH * lineHeight)
    return Gui.create({
      x = rowPosition.x,
      y = rowPosition.y,
      w = row.width,
      h = row.height,
      type = Gui.types.BUTTON,
      onClick = function(self)
        onSelect(name, optionValue)
      end,
      draw = function(self)
        if self.hovered then
          local sidePadding = 5
          love.graphics.setColor(1,1,0,0.5)
          local w = self.w + (sidePadding * 2)
          love.graphics.rectangle('fill', self.x - sidePadding, self.y, w, self.h)
        end
      end,
      drawOrder = function()
        return parent:drawOrder() - 1
      end
    }):setParent(self)
  end)
end

return Component.createFactory(MenuList)