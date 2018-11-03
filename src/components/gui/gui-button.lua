local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local f = require 'utils.functional'
local extend = require 'utils.object-utils'.extend
local Color = require 'modules.color'

local hoverColorMultiply = {0.8,0.8,0.8,1}

local Button = extend(Gui, {
  type = Gui.types.BUTTON,
  color = Color.PRIMARY,
  textColor = Color.WHITE,
  disabled = false,
  hidden = false,
  disabledStyle = {
    color = Color.LIGHT_GRAY,
    textColor = Color.OFF_WHITE,
    hoverColor = Color.LIGHT_GRAY
  },
  opacity = 1,
  padding = 0
})

Button.init = f.wrap(function(self)
  assert(self.textLayer ~= nil, '`textLayer` property is required')
  assert(
    Component.getBlueprint(self.textLayer) == GuiText,
    '`textLayer` should be an instance of GuiText'
  )
end, Gui.init)

Button.update = f.wrap(function(self)
  local buttonW = GuiText.getTextSize(self.text, self.textLayer.font)
  local buttonH = self.textLayer.font:getHeight()
  if self.hidden then
    self.w, self.h = 1, 1
  else
    self.w, self.h = buttonW + (self.padding * 2), buttonH + (self.padding * 2)
  end
end, Gui.update)

function Button.draw(self)
  if self.hidden then
    return
  end

  local w, h = self.w, self.h
  local buttonPadding = self.padding
  local styles = self.disabled and self.disabledStyle or self
  local btnColor, textColor = styles.color, styles.textColor
  local x, y = self.x, self.y
  local tx, ty = 0, self.hovered and -2 or 0
  if self.hovered then
    love.graphics.push()
    love.graphics.translate(0, ty)
  end

  love.graphics.setColor(btnColor)

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
    y + buttonPadding + ty
  )

  if self.hovered then
    love.graphics.pop()
  end
end

return Component.createFactory(Button)