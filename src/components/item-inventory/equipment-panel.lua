local Component = require 'modules.component'
local groups = require 'components.groups'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local Color = require 'modules.color'
local setupSlotInteractions = require 'components.item-inventory.slot-interaction'
local itemConfig = require 'components.item-inventory.items.config'

local EquipmentPanel = {
	group = groups.gui,
}

function EquipmentPanel.init(self)
	local function getSlots()
		return self.rootStore:get().equipment
	end

	local function onItemPickupFromSlot(slotX, slotY)
		print('pickup')
    return self.rootStore:unequipItem(slotX, slotY)
  end

	local function onItemDropToSlot(curPickedUpItem, slotX, slotY)
		local canEquip, itemSwap = self.rootStore:equipItem(
			curPickedUpItem, slotX, slotY
		)
		print('drop', canEquip, itemSwap)
		if canEquip then
			return itemSwap
		end
  end

	setupSlotInteractions(
		self,
		getSlots,
		10,
		onItemPickupFromSlot,
		onItemDropToSlot
	)
end

function EquipmentPanel.draw(self)
	local x, y, w, h = self.x, self.y, self.w, self.h
	guiTextLayers.title:add('Equipment', Color.WHITE, x, 20)
	love.graphics.setColor(0.2,0.2,0.2, 0.8)
	love.graphics.rectangle('fill', x, y, w, h)
end

return Component.createFactory(EquipmentPanel)