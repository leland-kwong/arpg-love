local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local font = require 'components.font'
local scale = require 'config'.scaleFactor

local GuiTestBlueprint = {}

local COLOR_BUTTON = {0,1,0.5,1}
local COLOR_BUTTON_HOVER = {0,0.9,0.8,1}
local COLOR_TOGGLE_BOX = Color.LIGHT_GRAY
local COLOR_TOGGLE_UNCHECKED = {0,0,0,0}
local COLOR_TOGGLE_CHECKED = {0,1,0.5,1}
local buttonPadding = 10

local function guiButton()
  local buttonText = love.graphics.newText(font.secondary.font, 'Button 1')
  local w, h = buttonText:getWidth(), buttonText:getHeight()

  return Gui.create({
    type = Gui.types.BUTTON,
    x = 200,
    y = 50,
    w = w + buttonPadding,
    h = h + buttonPadding,
    onClick = function(self)
      print('clicked!', self:getId())
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(scale)

      local x, y = self.x, self.y
      love.graphics.setColor(self.hovered and COLOR_BUTTON_HOVER or COLOR_BUTTON)
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

  return Gui.create({
    type = Gui.types.TOGGLE,
    x = 200,
    y = 100,
    w = toggleBoxSize + toggleText:getWidth(),
    h = toggleBoxSize,
    checked = true,
    onChange = function(self, checked)
      print('toggled!', checked)
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(scale)

      local x, y = self.x, self.y
      local w, h = self.w, self.h

      -- toggle box
      love.graphics.setColor(COLOR_TOGGLE_BOX)
      local lineWidth = 2
      love.graphics.translate(lineWidth / 2, 0)
      love.graphics.setLineWidth(lineWidth)
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

local function guiTextInput()
  local textGraphic = love.graphics.newText(font.secondary.font, 'foo')

  local blinkCursorCo = function()
    local show = true
    local frame = 0
    while true do
      frame = frame + 1
      if show and frame >= 28 then
        show = false
        frame = 0
      elseif not show and frame >= 25 then
        show = true
        frame = 0
      end
      coroutine.yield(show)
    end
  end

  return Gui.create({
    x = 200,
    y = 150,
    w = 200,
    h = 22,
    type = Gui.types.TEXT_INPUT,
    onFocus = function(self)
      self.blinkCursor = coroutine.wrap(blinkCursorCo)
    end,
    onBlur = function(self)
      self.blinkCursor = function() return false end
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(scale)

      -- text box
      love.graphics.setColor(
        self.focused and COLOR_BUTTON or Color.LIGHT_GRAY
      )
      local lineWidth = 2
      love.graphics.setLineWidth(lineWidth)
      love.graphics.translate(lineWidth / 2, lineWidth / 2)
      love.graphics.rectangle(
        'line',
        self.x,
        self.y,
        self.w - lineWidth * 2,
        self.h - lineWidth * 2
      )

      -- adjust content to center of text box
      love.graphics.translate(4, 5)

      -- draw text
      love.graphics.setColor(Color.WHITE)
      textGraphic:set(self.text)
      love.graphics.draw(textGraphic, self.x, self.y)

      -- draw cursor
      local isCursorVisible = self.focused and self.blinkCursor()
      if isCursorVisible then
        local w, h = textGraphic:getWidth(), font.secondary.fontSize + 2
        love.graphics.setColor(COLOR_BUTTON)
        love.graphics.rectangle(
          'fill',
          self.x + w,
          self.y - 1,
          2,
          h
        )
      end

      love.graphics.pop()
    end
  })
end

function GuiTestBlueprint.init(self)
  guiButton()
  guiToggle()
  guiTextInput()
end

return groups.gui.createFactory(GuiTestBlueprint)