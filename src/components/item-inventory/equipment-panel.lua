local Component = require 'modules.component'
local groups = require 'components.groups'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local Color = require 'modules.color'
local setupSlotInteractions = require 'components.item-inventory.slot-interaction'
local itemConfig = require 'components.item-inventory.items.config'
local animationFactory = require'components.animation-factory'
local Position = require 'utils.position'

local EquipmentPanel = {
	group = groups.gui,
}

function EquipmentPanel.init(self)
	local function getSlots()
		return self.rootStore:get().equipment
	end

	local function onItemPickupFromSlot(slotX, slotY)
    return self.rootStore:unequipItem(slotX, slotY)
  end

	local function onItemDropToSlot(curPickedUpItem, slotX, slotY)
		local canEquip, itemSwap = self.rootStore:equipItem(
			curPickedUpItem, slotX, slotY
		)
		if canEquip then
			return itemSwap
		else
			return curPickedUpItem
		end
	end

	local animationsCache = {}

	local function slotRenderer(item, screenX, screenY, slotX, slotY, slotW, slotH)
		local category = itemConfig.equipmentGuiSlotMap[slotY][slotX]
		local silhouette = itemConfig.equipmentCategorySilhouette[category]

		local showSilhouette = silhouette and (not item)
		if not showSilhouette then
			return
		end

		local animation = animationsCache[silhouette]
		if not animation then
			animation = animationFactory:new({ silhouette })
			animationsCache[silhouette] = animation
		end

		-- dark silhouette of item type that is allowed in slot
		local sx, sy, sw, sh = animation.sprite:getViewport()
		local offX, offY = Position.boxCenterOffset(sw, sh, slotW, slotH)
		love.graphics.setColor(0.35,0.35,0.35)
		love.graphics.setBlendMode('add', 'premultiplied')
		love.graphics.draw(
			animationFactory.atlas,
			animation.sprite,
			screenX,
			screenY,
			0,
			1,
			1,
			-offX,
			-offY
		)
		love.graphics.setBlendMode('alpha')
	end

	setupSlotInteractions(
		self,
		getSlots,
		10,
		onItemPickupFromSlot,
		onItemDropToSlot,
		slotRenderer
	)
end

function EquipmentPanel.draw(self)
	local x, y, w, h = self.x, self.y, self.w, self.h
	guiTextLayers.title:add('Equipment', Color.WHITE, x, 20)
	love.graphics.setColor(0.2,0.2,0.2, 0.8)
	love.graphics.rectangle('fill', x, y, w, h)
end

return Component.createFactory(EquipmentPanel)