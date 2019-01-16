local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'
local font = require 'components.font'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local animationFactory = require'components.animation-factory'
local itemSystem = require'components.item-inventory.items.item-system'
local Position = require 'utils.position'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local boxCenterOffset = Position.boxCenterOffset
local drawItem = require 'components.item-inventory.draw-item'
local Lru = require 'utils.lru'
local GlobalState = require 'main.global-state'
local InputContext = require 'modules.input-context'

local drawOrders = {
  GUI_SLOT = 3,
  GUI_SLOT_ITEM = 4,
  GUI_ITEM_PICKED_UP = 5,
  GUI_SLOT_TOOLTIP = 6,
  GUI_SLOT_TOOLTIP_CONTENT = 7
}

local spriteCache = Lru.new(100)
-- returns a static sprite for drawing
local function getSprite(name)
  local sprite = spriteCache:get(name)
  if (not sprite) then
    sprite = animationFactory:new({ name })
    spriteCache:set(name, sprite)
  end
  return sprite
end

local uiState = GlobalState.uiState
local pickedUpitem = {
  set = function(newItem)
    uiState:set('pickedUpItem', newItem)
  end,
  get = function()
    return uiState:get().pickedUpItem
  end
}

-- handles dropping items on the floor when its in the floor drop mode
local function handleItemDrop()
  local isDropModeFloor = InputContext.contains('any')
  if (isDropModeFloor and pickedUpitem.get()) then
    msgBus.send(msgBus.DROP_ITEM_ON_FLOOR, pickedUpitem.get())
    pickedUpitem.set(nil)
    msgBus.on(msgBus.MOUSE_CLICKED, function()
      msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, false)
      return msgBus.CLEANUP
    end)
    msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, true)
  end
end
msgBus.on(msgBus.MOUSE_PRESSED, handleItemDrop)

local function getSlotPosition(gridX, gridY, offsetX, offsetY, slotSize, margin)
  local posX, posY = ((gridX - 1) * slotSize) + ((gridX - 1) * margin) + offsetX,
    ((gridY - 1) * slotSize) + ((gridY - 1) * margin) + offsetY
  return posX, posY
end

-- handles the picked up item and makes it follow the cursor
Gui.create({
  type = Gui.types.INTERACT,
  inputContext = 'InventoryMenu',
  draw = function()
    if pickedUpitem.get() then
      local gameScale = config.scaleFactor
      local mx, my = love.mouse.getX() / gameScale, love.mouse.getY() / gameScale
      local sprite = itemSystem.getDefinition(pickedUpitem.get()).sprite
      local sw, sh = animationFactory:getSpriteSize(sprite, true)
      drawItem(pickedUpitem.get(), mx - sw/2, my - sh/2)
    end
  end,
  drawOrder = function()
    return drawOrders.GUI_ITEM_PICKED_UP
  end
})

-- sets up interactable gui nodes and renders the contents in each slot
local hoveredBgColor = {1,1,1,0.5}
local defaultSlotBackground = {0.1,0.1,0.1,1}
local defaultGetCustomProps = function()
  local O = require 'utils.object-utils'
  return O.EMPTY
end

local function setupSlotInteractions(
  self, getSlots, margin,
  onItemPickupFromSlot, onItemDropToSlot, onItemActivate,
  slotRenderer, getCustomProps
)
  local initialSlots = getSlots()
  getCustomProps = getCustomProps or defaultGetCustomProps
  -- setup the grid interaction
  require'utils.iterate-grid'(initialSlots, function(_, gridX, gridY)
    local posX, posY = getSlotPosition(gridX, gridY, self.x, self.y, self.slotSize, margin)
    -- we must get the item dynamically since the slots change when moving/deleting items around the inventory
    local function getItem()
      return getSlots()[gridY][gridX]
    end

    local tooltipRef
    local slotSize = self.slotSize
    local guiSlot = Gui.create({
      x = posX,
      y = posY,
      w = slotSize,
      h = slotSize,
      type = Gui.types.INTERACT,
      onUpdate = function(self)
        -- create a tooltip
        local item = getItem()
        if self.hovered and item and (not tooltipRef) then
          local itemState = itemSystem.getState(item)
          local Block = require 'components.gui.block'
          local itemConfig = require'components.item-inventory.items.config'
          local modParser = require 'modules.loot.item-modifier-template-parser'
          local blockPadding = 8
          local itemDef = itemSystem.getDefinition(item)
          local rarityColor = itemConfig.rarityColor[item.rarity]
          local tooltipWidth = 250
          local modifierBackgroundColor = {0.12,0.12,0.12}
          local titleBlock = {
            content = {
              rarityColor,
              item.customTitle or itemDef.title,
            },
            width = tooltipWidth * 5/8,
            font = font.secondary.font,
            fontSize = font.secondary.fontSize
          }
          local levelBlock = {
            content = {
              Color.WHITE,
              'Level '..(itemDef.levelRequirement or 1)
            },
            width = tooltipWidth * 3/8,
            align = 'right',
            font = font.primary.font,
            fontSize = font.primary.fontSize
          }

          local String = require 'utils.string'
          local rarityTypeText = itemConfig.rarityTitle[item.rarity]
          local itemTypeBlock = {
            content = {
              rarityColor,
              String.capitalize(
                (rarityTypeText and (rarityTypeText .. ' ') or '') .. itemConfig.categoryTitle[itemDef.category]
              )
            },
            width = tooltipWidth,
            font = font.primary.font,
            fontSize = font.primary.fontSize
          }

          local activeAbilityBlock = nil
          local definition = itemSystem.getDefinition(item)
          if definition.onActivateWhenEquipped then
            local module = itemSystem.loadModule(definition.onActivateWhenEquipped)
            if module.tooltip then
              activeAbilityBlock = Block.Row({
                {
                  content = modParser({
                    type = 'activeAbility',
                    data = module.tooltip(item)
                  }),
                  width = tooltipWidth,
                  font = font.primary.font,
                  fontSize = font.primary.fontSize,
                }
              }, {
                marginTop = blockPadding
              })
            end
          end

          local rightClickModule = itemSystem.loadModule(definition.onActivate)
          local Constants = require 'components.state.constants'
          local rightClickActionBlock = (not itemState.equipped) and
            Block.Row({
              {
                content = {
                  Color.PALE_YELLOW,
                  Constants.glyphs.rightMouseBtn..' to '..rightClickModule.tooltip(item)
                },
                width = tooltipWidth,
                align = 'right',
                font = font.primary.font,
                fontSize = font.primary.fontSize,
              }
            }, {
              marginTop = blockPadding
            }) or
            nil

          local Object = require 'utils.object-utils'
          local infoBlock = {
            content = modParser({
              type = 'baseStatsList',
              data = Object.assign({},
                itemSystem.getDefinition(item).info,
                itemSystem.getDefinition(item).baseModifiers
              )
            }),
            width = tooltipWidth,
            font = font.primary.font,
            fontSize = font.primary.fontSize,
          }
          local rows = {
            Block.Row({
              titleBlock,
              levelBlock
            }, {
              marginBottom = 3
            }),
            Block.Row({
              itemTypeBlock
            }, {
              marginBottom = 6
            }),
            Block.Row({
              infoBlock
            }, {
              marginBottom = blockPadding
            }),
          }

          local functional = require 'utils.functional'
          local extraModifiersRowProps = {
            marginTop = 1
          }
          -- add extra modifiers to tooltip
          local function showExtraModifiers(modifier)
            local module = itemSystem.loadModule(modifier)
            local tooltip = module.tooltip
            if tooltip then
              local content = tooltip(item)
              table.insert(rows, Block.Row({
                {
                  content = modParser(content),
                  width = tooltipWidth,
                  font = font.primary.font,
                  fontSize = font.primary.fontSize,
                  -- background = modifierBackgroundColor,
                  -- padding = blockPadding,
                }
              }, extraModifiersRowProps))
            end
          end
          functional.forEach(itemSystem.getDefinition(item).extraModifiers or {}, showExtraModifiers)
          functional.forEach(item.extraModifiers, showExtraModifiers)

          table.insert(rows, activeAbilityBlock)
          table.insert(rows, rightClickActionBlock)

          tooltipRef = Block.create({
            x = posX + self.w,
            y = posY,
            padding = 10,
            rows = rows,
            drawOrder = function()
              return drawOrders.GUI_SLOT_TOOLTIP_CONTENT
            end
          }):setParent(self)

          -- tooltip box background
          Component.create({
            group = 'gui',
            draw = function()
              local drawBox = require 'components.gui.utils.draw-box'
              drawBox(tooltipRef, 'tooltip')
            end,
            drawOrder = function()
              return drawOrders.GUI_SLOT_TOOLTIP
            end
          }):setParent(tooltipRef)
        end

        -- cleanup tooltip
        if ((not self.hovered or not item) and tooltipRef) then
          tooltipRef:delete(true)
          tooltipRef = nil
        end

        self.customProps = getCustomProps(getItem(), self.x, self.y, gridX, gridY, self.w, self.h)
      end,
      onClick = function(self, event)
        local isRightClick = event[3] == 2
        if isRightClick then
          local item = getItem()
          local d = itemSystem.getDefinition(item)
          if d and onItemActivate then
            onItemActivate(item)
          end
          return
        end
        local x, y = gridX, gridY
        local curPickedUpItem = pickedUpitem.get()
        -- if an item hasn't already been picked up, then we're in pickup mode
        local isPickingUp = (not pickedUpitem.get())
        if isPickingUp then
          pickedUpitem.set(onItemPickupFromSlot(x, y))
        -- drop picked up item to slot
        elseif curPickedUpItem then
          local itemSwap = onItemDropToSlot(curPickedUpItem, x, y)
          pickedUpitem.set(itemSwap)
        end
      end,
      drawOrder = function(self)
        return drawOrders.GUI_SLOT
      end,
      render = function(self)
        love.graphics.setColor(
          self.hovered and
            hoveredBgColor or
            (
              self.customProps.backgroundColor or
              defaultSlotBackground
            )
        )

        -- slot background
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

        local itemInSlot = getItem()
        if itemInSlot then
          local itemConfig = require(require('alias').path.items..'.config')
          if (itemInSlot.rarity ~= itemConfig.rarity.NORMAL) then
            local baseColor = itemConfig.rarityColor[itemInSlot.rarity]
            love.graphics.setColor(Color.multiplyAlpha(baseColor, 0.2))
            local oLineWidth = love.graphics.getLineWidth()
            local lw = 1
            love.graphics.setLineWidth(lw)
            love.graphics.rectangle('line', self.x + lw/2, self.y + lw/2, self.w - lw, self.h - lw)
            love.graphics.setLineWidth(oLineWidth)
            love.graphics.setColor(Color.multiplyAlpha(baseColor, 0.05))
            love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
          end
        end

        local item = getItem()
        if slotRenderer then
          slotRenderer(item, self.x, self.y, gridX, gridY, self.w, self.h)
        end
      end
    }):setParent(self.rootComponent)

    Component.create({
      init = function(self)
        Component.addToGroup(self:getId(), 'gui', self)
      end,
      draw = function()
        local item = getItem()
        drawItem(item, guiSlot.x, guiSlot.y, guiSlot.w)
      end,
      drawOrder = function()
        return drawOrders.GUI_SLOT_ITEM
      end
    }):setParent(self.rootComponent)
  end)
end

return setupSlotInteractions