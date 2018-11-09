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
  onSelectSound = 'built/sounds/gui/UI_SCI-FI_Tone_Deep_Dry_05_stereo.wav',
  -- table of menu options
  options = {
    {
      name = '', -- [STRING]
      value = {}, -- [ANY]
      onSelectSoundEnabled = true,
      onSelectDeleteMenu = false
    }
  },
  value = nil, -- selected value
  onSelect = nil,
  selectedBackgroundColor = {Color.multiplyAlpha(Color.PURPLE, 0.5)}
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
  local parent = self
  local isNewOptions = self.prevOptions ~= self.options
  if isNewOptions then
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
          if (option.onSelectSoundEnabled ~= false) then
            love.audio.play(
              love.audio.newSource(parent.onSelectSound, 'static')
            )
          end
          parent.value = option.value
          if option.onSelectDeleteMenu then
            parent:delete(true)
          end
        end,
        draw = function(self)
          if (parent.value == option.value) then
            love.graphics.setColor(parent.selectedBackgroundColor)
            love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
          end
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
    self.width = math.max(self.width, maxWidth)
    self.height = math.max(self.height, totalHeight)
  end
  self.prevOptions = self.options
end

return Component.createFactory(MenuList)