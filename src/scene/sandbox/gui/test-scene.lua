local Component = require 'modules.component'
local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local GuiTextInput = require 'components.gui.gui-text-input'
local GuiText = require 'components.gui.gui-text'
local GuiList = require 'components.gui.gui-list'
local Button = require 'components.gui.gui-button'
local Color = require 'modules.color'
local font = require 'components.font'
local msgBus = require 'components.msg-bus'
local scale = require 'config.config'.scaleFactor

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

function GuiTestBlueprint.init(self)
  local guiState = {
    slider = {
      isDragStart = false,
      beforeDragValue = 0,
      value = 0
    }
  }

  local gsa = require 'main.global-state'
  gsa.setBackgroundColor({0.5,0.5,0.5,})

  local guiText = GuiText.create({
    group = groups.gui
  })

  local function guiToggle(x, y, toggleText)
    local toggleBoxSize = 14
    local toggleTextWidth = GuiText.getTextSize(toggleText, guiText.font)

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

  local children = {
    Button.create({
      x = 200,
      y = 50,
      w = 70,
      padding = 4,
      text = 'Button 1',
      textLayer = guiText,
      onClick = function(self)
        consoleLog(self.text..' clicked')
      end
    }),
    Button.create({
      x = 300,
      y = 50,
      w = 70,
      padding = 4,
      text = 'Button 2',
      textLayer = guiText,
      onClick = function(self)
        consoleLog(self.text..' clicked')
      end
    }),
    guiToggle(200, 100, 'music'),
    guiToggle(200, 125, 'sound effects'),
    GuiTextInput.create({
      x = 200,
      y = 165,
      w = 200,
      padding = 5,
      textLayer = guiText,
      placeholderText = 'player name'
    }),
    guiText,
  }
  local list = GuiList.create({
    childNodes = children,
    x = 180,
    y = 30,
    width = 240,
    height = 200,
    contentHeight = 280
  }):setParent(self)
end

function GuiTestBlueprint.final()
  consoleLog('scene deleted')
end

return Component.createFactory(GuiTestBlueprint)