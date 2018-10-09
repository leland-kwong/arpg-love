local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local objectUtils = require 'utils.object-utils'
local Color = require 'modules.color'

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
    local ctrlColor = self.focused and Color.PRIMARY or Color.LIGHT_GRAY

    -- text box
    love.graphics.setColor(ctrlColor)
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
    local tx2, ty2 = 4, 5
    love.graphics.translate(tx2, ty2)

    -- placeholder text
    local placeholderOffX, placeholderOffY = 0, 0
    local hasContent = #self.text > 0
    if self.focused or hasContent then
      placeholderOffX, placeholderOffY = 0, -self.h + 2
    end

    self.textLayer:add(
      self.placeholderText,
      ctrlColor,
      posX + placeholderOffX + tx + tx2,
      posY + placeholderOffY + ty + ty2
    )

    -- draw text
    self.textLayer:add(
      self.text,
      Color.WHITE,
      posX + tx + tx2,
      posY + ty + ty2
    )

    -- draw cursor
    local isCursorVisible = self.focused and self.blinkCursor()
    if isCursorVisible then
      local w = GuiText.getTextSize(self.text, self.textLayer.font)
      local h = self.textLayer.font:getHeight()
      love.graphics.setColor(Color.PRIMARY)
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

return Component.createFactory(GuiTextInput)