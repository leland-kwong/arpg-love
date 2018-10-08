local Component = require 'modules.component'
local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local GuiTextInput = require 'components.gui.gui-text-input'
local GuiTextLayer = require 'components.gui.gui-text'
local GuiList = require 'components.gui.gui-list'
local Color = require 'modules.color'
local font = require 'components.font'
local pprint = require 'utils.pprint'
local scale = require 'config.config'.scaleFactor

local guiText = GuiTextLayer.create({
  group = groups.gui
})

local GuiTestBlueprint = {
  group = groups.gui,
  dx = 0,
  dy = 0
}

local COLOR_PRIMARY = Color.PRIMARY
local COLOR_BUTTON_HOVER = {0,0.9,0.8,1}
local COLOR_TOGGLE_BOX = Color.LIGHT_GRAY
local COLOR_TOGGLE_UNCHECKED = {0,0,0,0}
local COLOR_TOGGLE_CHECKED = COLOR_PRIMARY
local buttonPadding = 10

local textForMeasuring = love.graphics.newText(font.secondary.font, '')
local function getTextSize(text)
  textForMeasuring:set(text)
  return textForMeasuring:getWidth(), textForMeasuring:getHeight()
end

local function guiButton(x, y, w, h, buttonText)
  local buttonW, buttonH = getTextSize(buttonText)
  w, h = w or buttonW, h or buttonH

  return Gui.create({
    type = Gui.types.BUTTON,
    x = x,
    y = y,
    w = w + buttonPadding,
    h = h + buttonPadding,
    onClick = function(self)
      print('clicked!', self:getId())
    end,
    render = function(self)
      local x, y = self.x, self.y
      love.graphics.setColor(self.hovered and COLOR_BUTTON_HOVER or COLOR_PRIMARY)
      love.graphics.rectangle(
        'fill',
        x, y,
        w + buttonPadding, h + buttonPadding
      )
      guiText:add(
        buttonText,
        Color.WHITE,
        x + buttonPadding / 2,
        y + buttonPadding / 2
      )
    end
  })
end

local function guiToggle(x, y, toggleText)
  local toggleBoxSize = 14
  local toggleTextWidth = getTextSize(toggleText)

  return Gui.create({
    type = Gui.types.TOGGLE,
    x = x,
    y = y,
    w = toggleBoxSize + toggleTextWidth,
    h = toggleBoxSize,
    checked = true,
    onChange = function(self, checked)
      print('toggled!', checked)
    end,
    render = function(self)
      love.graphics.push()

      local x, y = self:getPosition()
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
      guiText:add(
        toggleText,
        Color.WHITE,
        self.x + 2 + toggleBoxSize,
        self.y + 1
      )

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
  local children = {
    guiButton(200, 50, 70, nil, 'Button 1'),
    guiButton(300, 50, 70, nil, 'Button 2'),
    guiToggle(200, 100, 'music'),
    guiToggle(200, 125, 'sound effects'),
    GuiTextInput.create({
      x = 200,
      y = 165,
      w = 200,
      h = 22,
      textLayer = guiText,
      placeholderText = 'player name'
    }),
    guiText
  }
  local list = GuiList.create({
    childNodes = children,
    x = 180,
    y = 30,
    width = 240,
    height = 100,
    contentHeight = 200
  }):setParent(self)
end

return Component.createFactory(GuiTestBlueprint)