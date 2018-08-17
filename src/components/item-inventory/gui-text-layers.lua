local GuiText = require 'components.gui.gui-text'
local font = require 'components.font'

local guiTextLayerTitle = GuiText.create({
	font = font.secondary.font,
	drawOrder = function()
		return 7
	end
})

local guiTextLayerBody = GuiText.create({
	font = font.primary.font,
	drawOrder = function()
		return 7
	end
})

return {
	title = guiTextLayerTitle,
	body = guiTextLayerBody
}