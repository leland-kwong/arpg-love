local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local f = require 'utils.functional'
local extend = require 'utils.object-utils'.extend
local Color = require 'modules.color'

local Button = extend(Gui, {
  type = Gui.types.BUTTON,
  color = Color.PRIMARY,
  hoverColor = Color.LIME,
  textColor = Color.WHITE,
  disabled = false,
  disabledStyle = {
    color = Color.LIGHT_GRAY,
    textColor = Color.OFF_WHITE,
    hoverColor = Color.LIGHT_GRAY
  },
  opacity = 1,
  padding = 0
})

Button.init = f.wrap(function(self)
  assert(
    Component.getBlueprint(self.textLayer) == GuiText,
    '`textLayer` should be an instance of GuiText'
  )
  local buttonW = GuiText.getTextSize(self.text, self.textLayer.font)
  local buttonH = self.textLayer.font:getHeight()
  self.w, self.h = (self.w or buttonW) + (self.padding * 2), (self.h or buttonH) + (self.padding * 2)
end, Gui.init)

function Button.draw(self)
  local w, h = self.w, self.h
  local buttonPadding = self.padding
  local styles = self.disabled and self.disabledStyle or self
  local btnColor, textColor, hoverColor = styles.color, styles.textColor, styles.hoverColor
  local x, y = self.x, self.y
  love.graphics.setColor(self.hovered and hoverColor or btnColor)
  love.graphics.rectangle(
    'fill',
    x, y,
    w,
    h
  )
  self.textLayer:add(
    self.text,
    textColor,
    x + buttonPadding,
    y + buttonPadding
  )
end

return Component.createFactory(Button)