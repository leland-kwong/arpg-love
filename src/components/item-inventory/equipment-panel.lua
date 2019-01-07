local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local groups = require 'components.groups'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local Color = require 'modules.color'
local setupSlotInteractions = require 'components.item-inventory.slot-interaction'
local itemConfig = require 'components.item-inventory.items.config'
local animationFactory = require'components.animation-factory'
local Position = require 'utils.position'
local itemSystem = require'components.item-inventory.items.item-system'
local itemConfig = require 'components.item-inventory.items.config'
local msgBus = require 'components.msg-bus'
local uiState = require 'main.global-state'.uiState

local function getItemCategory(slotX, slotY)
	local Grid = require 'utils.grid'
	return Grid.get(itemConfig.equipmentGuiSlotMap, slotX, slotY)
end

local EquipmentPanel = {
	group = groups.gui,
}

function EquipmentPanel.init(self)
	local function getSlots()
		return self.rootStore:get().equipment
	end

	self.clock = 0

	local parent = self
  Gui.create({
    id = 'EquipmentPanelRegion',
    x = parent.x,
    y = parent.y,
    inputContext = 'EquipmentPanel',
    onUpdate = function(self)
      self.w = parent.w
      self.h = parent.h
    end,
  }):setParent(self)

	local function onItemPickupFromSlot(slotX, slotY)
		-- IMPORTANT: make sure we unequip the item before triggering the messages
		local unequippedItem = self.rootStore:unequipItem(slotX, slotY)
		msgBus.send(msgBus.INVENTORY_PICKUP)
		msgBus.send(msgBus.EQUIPMENT_CHANGE)
		return unequippedItem
  end

	local function onItemDropToSlot(curPickedUpItem, slotX, slotY)
		local canEquip, itemSwap = self.rootStore:equipItem(
			curPickedUpItem, slotX, slotY
		)
		if canEquip then
			msgBus.send(msgBus.INVENTORY_DROP)
			msgBus.send(msgBus.EQUIPMENT_CHANGE)
			return itemSwap
		else
			return curPickedUpItem
		end
	end

	local animationsCache = {}

	local function slotRenderer(item, screenX, screenY, slotX, slotY, slotW, slotH)
		local category = getItemCategory(slotX, slotY)
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
		15,
		onItemPickupFromSlot,
		onItemDropToSlot,
		nil,
		slotRenderer,
		function(item, screenX, screenY, slotX, slotY)
			local Color = require 'modules.color'
			local pickedUpItem = uiState:get().pickedUpItem
			local isValidSlotForItem = pickedUpItem and
				(getItemCategory(slotX, slotY) == itemSystem.getDefinition(pickedUpItem).category)
			local alpha = math.max(math.sin(self.clock), 0.3)
			local bgColor = isValidSlotForItem and
				{Color.multiplyAlpha(Color.PALE_YELLOW, alpha)} or
				nil
			return {
				backgroundColor = bgColor
			}
		end
	)
end

function EquipmentPanel.update(self, dt)
	self.clock = self.clock + dt * 8
end

function EquipmentPanel.draw(self)
	local x, y, w, h = self.x, self.y, self.w, self.h
	guiTextLayers.title:add('Equipment', Color.WHITE, x, self.y - 15)

	love.graphics.setColor(0.2,0.2,0.2, 1)
	love.graphics.rectangle('fill', x, y, w, h)

	love.graphics.setColor(Color.multiplyAlpha(Color.SKY_BLUE, 0.5))
  love.graphics.rectangle('line', x, y, w, h)
end

return Component.createFactory(EquipmentPanel)