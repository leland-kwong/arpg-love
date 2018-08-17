local Component = require 'modules.component'
local groups = require 'components.groups'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local Color = require 'modules.color'

local EquipmentPanel = {
	group = groups.gui
}

function EquipmentPanel.draw(self)
	local x, y, w, h = self.x, self.y, self.w, self.h
	guiTextLayers.title:add('Equipment', Color.WHITE, x, 20)
	love.graphics.setColor(0.2,0.2,0.2, 0.8)
	love.graphics.rectangle('fill', x, y, w, h)
end

return Component.createFactory(EquipmentPanel)