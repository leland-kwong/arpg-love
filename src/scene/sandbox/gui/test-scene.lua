local groups = require 'components.groups'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local font = require 'components.font'
local scale = require 'config'.scaleFactor

local GuiTestBlueprint = {
  dx = 0,
  dy = 0
}

local COLOR_PRIMARY = {0.3,0.9,0.6,1}
local COLOR_BUTTON_HOVER = {0,0.9,0.8,1}
local COLOR_TOGGLE_BOX = Color.LIGHT_GRAY
local COLOR_TOGGLE_UNCHECKED = {0,0,0,0}
local COLOR_TOGGLE_CHECKED = COLOR_PRIMARY
local buttonPadding = 10

local function guiButton(x, y, w, h, buttonText)
  local buttonText = love.graphics.newText(font.secondary.font, buttonText)
  local w, h = w or buttonText:getWidth(), h or buttonText:getHeight()

  return Gui.create({
    type = Gui.types.BUTTON,
    x = x,
    y = y,
    w = w + buttonPadding,
    h = h + buttonPadding,
    scale = scale,
    onClick = function(self)
      print('clicked!', self:getId())
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(self.scale)
      local x, y = self.x, self.y
      love.graphics.setColor(self.hovered and COLOR_BUTTON_HOVER or COLOR_PRIMARY)
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

local function guiToggle(x, y, toggleText)
  local toggleText = love.graphics.newText(font.secondary.font, toggleText)
  local toggleBoxSize = 14

  return Gui.create({
    type = Gui.types.TOGGLE,
    x = x,
    y = y,
    w = toggleBoxSize + toggleText:getWidth(),
    h = toggleBoxSize,
    scale = scale,
    checked = true,
    onChange = function(self, checked)
      print('toggled!', checked)
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(self.scale)

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

local function guiTextInput(x, y, w, h, scale, placeholder)
  local textGraphic = love.graphics.newText(font.secondary.font, '')

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
    x = x,
    y = y,
    w = w,
    h = h,
    placeholder = placeholder,
    scale = scale,
    type = Gui.types.TEXT_INPUT,
    onFocus = function(self)
      self.blinkCursor = coroutine.wrap(blinkCursorCo)
    end,
    onBlur = function(self)
      self.blinkCursor = function() return false end
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(self.scale)
      local posX, posY = self:getPosition()

      -- text box
      love.graphics.setColor(
        self.focused and COLOR_PRIMARY or Color.LIGHT_GRAY
      )
      local lineWidth = 2
      love.graphics.setLineWidth(lineWidth)
      local tx, ty = lineWidth / 2, lineWidth / 2
      love.graphics.translate(tx, ty)
      love.graphics.rectangle(
        'line',
        posX,
        posY,
        self.w - lineWidth * 2,
        self.h - lineWidth * 2
      )

      -- adjust content to center of text box
      love.graphics.translate(4, 5)

      -- placeholder text
      local placeholderOffX, placeholderOffY = 0, 0
      local hasContent = #self.text > 0
      if self.focused or hasContent then
        placeholderOffX, placeholderOffY = 0, -self.h + 2
      end
      textGraphic:set(self.placeholder)
      love.graphics.draw(textGraphic, posX + placeholderOffX, posY + placeholderOffY)

      -- draw text
      love.graphics.setColor(Color.WHITE)
      textGraphic:set(self.text)
      love.graphics.draw(textGraphic, posX, posY)

      -- draw cursor
      local isCursorVisible = self.focused and self.blinkCursor()
      if isCursorVisible then
        local w, h = textGraphic:getWidth(), font.secondary.fontSize + 2
        love.graphics.setColor(COLOR_PRIMARY)
        love.graphics.rectangle(
          'fill',
          posX + w,
          posY - 1,
          2,
          h
        )
      end

      love.graphics.pop()
    end
  })
end

local function guiList(parent, children)
  local function scrollbars(self)
    local scrollbarWidth = 5

    if self.scrollHeight > 0 then
      love.graphics.setColor(COLOR_PRIMARY)
      love.graphics.rectangle(
        'fill',
        self.x + self.w - scrollbarWidth,
        self.y - self.scrollTop,
        scrollbarWidth,
        self.h - self.scrollHeight
      )
    end

    if self.scrollWidth > 0 then
      love.graphics.setColor(COLOR_PRIMARY)
      love.graphics.rectangle(
        'fill',
        self.x - self.scrollLeft,
        self.y + self.h - scrollbarWidth,
        self.w - self.scrollWidth,
        scrollbarWidth
      )
    end
  end

  return Gui.create({
    x = 180,
    y = 1,
    w = 240,
    h = 360,
    scale = scale,
    type = Gui.types.LIST,
    children = children,
    scrollHeight = 50,
    onScroll = function(self)
    end,
    render = function(self)
      love.graphics.push()
      love.graphics.scale(self.scale)
      love.graphics.setColor(0.1,0.1,0.1)

      local posX, posY = self:getPosition()
      love.graphics.rectangle(
        'fill',
        posX,
        posY,
        self.w,
        self.h
      )
      scrollbars(self)
      love.graphics.pop()
    end,
    drawOrder = function(self)
      return 1
    end
  })
end

function GuiTestBlueprint.init(self)
  local children = {
    guiButton(200, 50, 70, nil, 'Button 1'),
    guiButton(300, 50, 70, nil, 'Button 2'),
    guiToggle(200, 100, 'music'),
    guiToggle(200, 125, 'sound effects'),
    guiTextInput(
      200,
      165,
      200,
      22,
      2,
      'player name'
    )
  }
  local list = guiList(self, children)
end

return groups.gui.createFactory(GuiTestBlueprint)