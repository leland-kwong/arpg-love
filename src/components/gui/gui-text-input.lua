local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local objectUtils = require 'utils.object-utils'
local Color = require 'modules.color'
local Position = require 'utils.position'

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

local GuiTextInput = objectUtils.extend(Gui, {
  textColor = Color.WHITE,
  borderColor = Color.PRIMARY,
  cursorColor = Color.YELLOW,
  init = function(self)
    assert(
      self.textLayer
        and (Component.getBlueprint(self.textLayer) == GuiText),
      'text layer must be provided'
    )
    Gui.init(self)
  end,
  placeholderText = 'type to enter text',
  type = Gui.types.TEXT_INPUT,
  onFocus = function(self)
    self.blinkCursor = coroutine.wrap(blinkCursorCo)
  end,
  onBlur = function(self)
    self.blinkCursor = function() return false end
  end,
  render = function(self)
    love.graphics.push()

    local cursorType = self.hovered and CURSOR_TEXT or nil
    love.mouse.setCursor(cursorType)

    local posX, posY = self:getPosition()
    local ctrlColor = self.focused and self.borderColor or Color.LIGHT_GRAY

    -- text box
    love.graphics.setColor(ctrlColor)
    local lineWidth = 2
    love.graphics.setLineWidth(lineWidth)
    love.graphics.rectangle(
      'line',
      posX,
      posY,
      self.w,
      self.h
    )

    -- placeholder text
    local placeholderOffX, placeholderOffY = 0, 0
    local textHeight = self.textLayer.font:getHeight()
    local cx, cy = Position.boxCenterOffset(self.w, textHeight, self.w + (lineWidth * 2), self.h + (lineWidth))
    local textX, textY = posX + lineWidth + 5, posY + cy
    local hasContent = #self.text > 0
    if self.focused or hasContent then
      placeholderOffX, placeholderOffY = 0, -self.h
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
      local w = GuiText.getTextSize(self.text, self.textLayer.font)
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