local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local font = require 'components.font'
local scale = require 'config'.scaleFactor

local GuiTestBlueprint = {}

local COLOR_BUTTON = {0,1,0.5,1}
local COLOR_BUTTON_HOVER = {0,0.9,0.8,1}
local COLOR_TOGGLE_BOX = {0.5,0.5,0.5}
local COLOR_TOGGLE_UNCHECKED = {0,0,0,0}
local COLOR_TOGGLE_CHECKED = {0,1,0.5,1}
local buttonPadding = 10

local function guiButton()
  local buttonText = love.graphics.newText(font.secondary.font, 'Button 1')
  local w, h = buttonText:getWidth(), buttonText:getHeight()
  Gui.create({
    x = 200,
    y = 50,
    w = w + buttonPadding,
    h = h + buttonPadding,
    onClick = function(self)
      print('clicked!', self._id)
    end,
    type = Gui.types.BUTTON,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(scale)

      local x, y = self.x, self.y
      love.graphics.setColor(self.buttonHovered and COLOR_BUTTON_HOVER or COLOR_BUTTON)
      love.graphics.rectangle(
        'fill',
        x, y,
        w + buttonPadding, h + buttonPadding
      )
      love.graphics.setColor(0,0,0)
      love.graphics.draw(
        buttonText,
        x + buttonPadding / 2,
        y + buttonPadding / 2
      )

      love.graphics.pop()
    end
  })
end

local function guiToggle()
  local toggleText = love.graphics.newText(font.secondary.font, 'Toggle')
  local toggleBoxSize = 14

  Gui.create({
    x = 200,
    y = 100,
    w = toggleBoxSize + toggleText:getWidth(),
    h = toggleBoxSize,
    checked = true,
    onChange = function(self, checked)
      print('toggled!', checked)
    end,
    type = Gui.types.TOGGLE,
    render = function(self)
      love.graphics.push()
      love.graphics.translate(2, 0)
      love.graphics.scale(scale)

      local x, y = self.x, self.y
      local w, h = self.w, self.h

      -- toggle box
      love.graphics.setColor(COLOR_TOGGLE_BOX)
      local lineWidth = 2
      love.graphics.setLineWidth(2)
      love.graphics.rectangle(
        'line',
        x, y,
        toggleBoxSize - lineWidth*2, toggleBoxSize - lineWidth*2
      )

      love.graphics.setColor(Color.WHITE)
      love.graphics.draw(toggleText, self.x + 2 + toggleBoxSize, self.y + 1)

      local toggleColor = self.checked and COLOR_TOGGLE_CHECKED or COLOR_TOGGLE_UNCHECKED
      love.graphics.setColor(toggleColor)
      love.graphics.rectangle(
        'fill',
        x + lineWidth/2, y + lineWidth/2,
        toggleBoxSize - lineWidth*2 - 2, h - lineWidth*2 - 2
      )

      love.graphics.pop()
    end
  })
end

function GuiTestBlueprint.init(self)
  guiButton()
  guiToggle()
end

return groups.gui.createFactory(GuiTestBlueprint)