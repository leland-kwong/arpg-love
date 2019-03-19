return function (text, font)
  local GuiText = require 'components.gui.gui-text'
  return GuiText.getTextSize(text, font)
end