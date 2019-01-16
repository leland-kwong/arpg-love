local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local objectUtils = require 'utils.object-utils'
local Color = require 'modules.color'
local Position = require 'utils.position'
local f = require 'utils.functional'

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

local CURSOR_TEXT = love.mouse.getSystemCursor('ibeam')

local callbacks = {
  onFocus = function(self)
    self.blinkCursor = coroutine.wrap(blinkCursorCo)
  end,
  onKeyPress = function(self)
    self.blinkCursor = coroutine.wrap(blinkCursorCo)
  end,
  onBlur = function(self)
    self.blinkCursor = function() return false end
  end,
}

local GuiTextInput = objectUtils.assign({}, Gui, {
  padding = 0,
  textColor = Color.WHITE,
  borderColor = Color.WHITE,
  cursorColor = Color.YELLOW,
  init = function(self)
    assert(
      self.textLayer
        and (Component.getBlueprint(self.textLayer) == GuiText),
      'text layer must be provided'
    )
    Gui.init(self)

    -- wrap callbacks
    for ev,cb in pairs(callbacks) do
      local originalCallback = self[ev]
      self[ev] = function(...)
        originalCallback(...)
        cb(...)
      end
    end
  end,
  placeholderText = 'type to enter text',
  type = Gui.types.TEXT_INPUT,
  update = f.wrap(Gui.update, function(self)
    local textHeight = self.textLayer.font:getHeight()
    self.h = textHeight + (self.padding * 2)
    self.textHeight = textHeight
  end),
  render = function(self)
    local textHeight = self.textHeight

    love.graphics.push()

    local cursorType = self.hovered and CURSOR_TEXT or nil
    love.mouse.setCursor(cursorType)

    local posX, posY = self:getPosition()
    local ctrlColor = self.focused and self.borderColor or Color.LIGHT_GRAY
    local boxHeight = self.h

    -- text box
    love.graphics.setColor(ctrlColor)
    local lineWidth = 1
    love.graphics.setLineWidth(lineWidth)
    love.graphics.rectangle(
      'line',
      posX + lineWidth/2,
      posY + lineWidth/2,
      self.w - lineWidth,
      boxHeight - lineWidth
    )

    -- placeholder text
    local placeholderOffX, placeholderOffY = 0, 0
    local cx, cy = Position.boxCenterOffset(self.w, textHeight, self.w + (lineWidth * 2), boxHeight + (lineWidth))
    local textX, textY = posX + lineWidth + 5, posY + cy
    local hasContent = #self.text > 0
    if self.focused or hasContent then
      placeholderOffX, placeholderOffY = 0, -boxHeight
    end

    -- draw placeholder text
    self.textLayer:add(
      self.placeholderText,
      ctrlColor,
      textX + placeholderOffX,
      textY + placeholderOffY
    )

    -- draw text
    self.textLayer:add(
      self.text,
      self.textColor,
      textX,
      textY
    )

    -- draw cursor
    local isCursorVisible = self.focused and self.blinkCursor()
    if isCursorVisible then
      local w = self.textLayer.font:getWidth(self.text)
      love.graphics.setColor(self.cursorColor)
      love.graphics.rectangle(
        'fill',
        textX + w,
        textY - 1,
        2,
        textHeight
      )
    end

    love.graphics.pop()
  end
})

return Component.createFactory(GuiTextInput)