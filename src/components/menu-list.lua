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
  width = 300,
  height = 1,
  padding = 10,
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
  self.guiBlock = GuiBlock.create({
    x = self.x,
    y = self.y,
    rows = {},
    drawOrder = function()
      return parent:drawOrder() + 1
    end,
    textOutline = true
  }):setParent(self)
end

function MenuList.update(self)
  local isNewOptions = self.prevOptions ~= self.options
  if isNewOptions then
    local parent = self
    local itemFont = font.primary.font

    local onSelect = self.onSelect
    local menuX = self.x
    local menuY = self.y
    local startYOffset = 10
    local menuWidth = self.width

    local rows = f.map(self.options, function(options)
      local name = options.name
      local content = type(name) == 'table' and name or {Color.WHITE, name}
      return GuiBlock.Row({
        {
          content = content,
          width = menuWidth,
          padding = self.padding,
          font = itemFont,
          fontSize = itemFont:getHeight()
        }
      })
    end)
    self.guiBlock.rows = rows

    -- remove interact nodes each frame
    f.forEach(self.interactNodes, function(node)
      node:delete(true)
    end)

    -- recreate interact nodes
    self.interactNodes = {}
    local totalHeight = 0
    local maxWidth = 1 -- needs to be at least 1 so the `bump` library doesn't complain
    -- menu option gui nodes
    guiBlockLayout(rows, self.x, self.y, function(row, rowPosition, _, _, rowIndex)
      local option = self.options[rowIndex]
      local name = option.name
      local optionValue = option.value
      local textW, textH = GuiText.getTextSize(name, itemFont)
      local lineHeight = 1.8
      local node = Gui.create({
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
            love.graphics.setColor(1,1,0,0.5)
            love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
          end
        end,
        drawOrder = function()
          return parent:drawOrder() - 1
        end
      }):setParent(self)
      table.insert(self.interactNodes, node)
      totalHeight = totalHeight + row.height
      maxWidth = math.max(maxWidth, row.width)
    end)
    self.width = maxWidth
    self.height = totalHeight
  end
  self.prevOptions = self.options
end

return Component.createFactory(MenuList)