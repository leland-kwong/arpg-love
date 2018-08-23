local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'
local groups = require 'components.groups'
local f = require 'utils.functional'
local font = require 'components.font'
local Color = require 'modules.color'
local Position = require 'utils.position'

local SandboxSceneSelection = {
  x = 200,
  y = 20,
  group = groups.gui,
  -- table of menu options
  options = {},
  onSelect = nil
}

local itemFont = font.primary.font
local titleFont = font.secondary.font
local guiTextBodyLayer = GuiText.create({
  font = itemFont
})
local guiTextTitleLayer = GuiText.create({
  font = titleFont
})

function SandboxSceneSelection.init(self)
  assert(type(self.onSelect) == 'function', 'onSelect method required')

  local onSelect = self.onSelect
  local menuX = self.x
  local menuY = self.y
  local startYOffset = 10
  local menuWidth = math.max(
    unpack(
      f.map(self.options, function(option)
        return GuiText.getTextSize(option.name, itemFont)
      end)
    )
  )

  -- menu option gui nodes
  local menuOptions = f.map(self.options, function(option, i)
    local name = option.name
    local optionValue = option.value
    local textW, textH = GuiText.getTextSize(name, itemFont)
    local lineHeight = 1.8
    local h = (textH * lineHeight)
    return Gui.create({
      x = menuX,
      y = i * h + menuY + startYOffset,
      w = menuWidth,
      h = h,
      type = Gui.types.BUTTON,
      onClick = function(self)
        onSelect(name, optionValue)
      end,
      draw = function(self)
        if self.hovered then
          local sidePadding = 5
          love.graphics.setColor(1,1,0,0.5)
          local w = self.w + (sidePadding * 2)
          love.graphics.rectangle('fill', self.x - sidePadding, self.y - self.h/4, w, self.h)
        end
        guiTextBodyLayer:add(name, Color.WHITE, self.x, self.y)
      end,
      drawOrder = function()
        return 5
      end
    }):setParent(self)
  end)
end

function SandboxSceneSelection.draw(self)
  guiTextTitleLayer:add('Sandbox scenes', Color.WHITE, self.x, self.y)
end

return Component.createFactory(SandboxSceneSelection)