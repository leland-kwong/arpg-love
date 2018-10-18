local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'
local font = require 'components.font'
local guiTextLayers = require 'components.item-inventory.gui-text-layers'
local animationFactory = require'components.animation-factory'
local itemDefinition = require'components.item-inventory.items.item-system'
local Position = require 'utils.position'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local boxCenterOffset = Position.boxCenterOffset
local drawItem = require 'components.item-inventory.draw-item'
local Lru = require 'utils.lru'

local drawOrders = {
  GUI_SLOT = 3,
  GUI_SLOT_ITEM = 4,
  GUI_SLOT_TOOLTIP = 5
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

-- currently picked up item. We can only have one item picked up at a time
local itemPickedUp = nil
local isDropModeFloor = false

msgBus.on(msgBus.INVENTORY_DROP_MODE_INVENTORY, function()
  isDropModeFloor = false
end)
msgBus.on(msgBus.INVENTORY_DROP_MODE_FLOOR, function()
  isDropModeFloor = true
end)
-- handles dropping items on the floor when its in the floor drop mode
local function handleItemDrop()
  if (isDropModeFloor and itemPickedUp) then
    msgBus.send(msgBus.DROP_ITEM_ON_FLOOR, itemPickedUp)
    itemPickedUp = nil
    msgBus.on(msgBus.MOUSE_CLICKED, function()
      msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, false)
      return msgBus.CLEANUP
    end)
    msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, true)
  end
end
msgBus.on(msgBus.MOUSE_PRESSED, handleItemDrop)

local function getSlotPosition(gridX, gridY, offsetX, offsetY, slotSize, margin)
  local posX, posY = ((gridX - 1) * slotSize) + (gridX * margin) + offsetX,
    ((gridY - 1) * slotSize) + (gridY * margin) + offsetY
  return posX, posY
end

-- handles the picked up item and makes it follow the cursor
Gui.create({
  type = Gui.types.INTERACT,
  inputContext = 'InventoryMenu',
  draw = function()
    if itemPickedUp then
      local gameScale = config.scaleFactor
      local mx, my = love.mouse.getX() / gameScale, love.mouse.getY() / gameScale
      local sprite = itemDefinition.getDefinition(itemPickedUp).sprite
      local sw, sh = animationFactory:getSpriteSize(sprite, true)
      drawItem(itemPickedUp, mx - sw/2, my - sh/2)
    end
  end,
  drawOrder = function()
    return 4
  end
})

-- sets up interactable gui nodes and renders the contents in each slot
local defaultSlotBackground = {0.1,0.1,0.1,1}
local function setupSlotInteractions(
  self, getSlots, margin,
  onItemPickupFromSlot, onItemDropToSlot, onItemActivate,
  slotRenderer
)
  local rootStore = self.rootStore
  local initialSlots = getSlots()
  -- setup the grid interaction
  require'utils.iterate-grid'(initialSlots, function(_, gridX, gridY)
    local posX, posY = getSlotPosition(gridX, gridY, self.x, self.y, self.slotSize, margin)
    -- we must get the item dynamically since the slots change when moving/deleting items around the inventory
    local function getItem()
      return getSlots()[gridY][gridX]
    end

    local slotSize = self.slotSize
    local guiSlot = Gui.create({
      x = posX,
      y = posY,
      w = slotSize,
      h = slotSize,
      inputContext = self.inputContext,
      type = Gui.types.INTERACT,
      onUpdate = function(self)
        -- create a tooltip
        local item = getItem()
        if self.hovered and item and (not self.tooltip) then
          local itemState = itemDefinition.getState(item)
          local Block = require 'components.gui.block'
          local itemConfig = require'components.item-inventory.items.config'
          local modParser = require 'modules.loot.item-modifier-template-parser'
          local blockPadding = 8
          local itemDef = itemDefinition.getDefinition(item)
          local rarityColor = itemConfig.rarityColor[item.rarity]
          local tooltipWidth = 250
          local modifierBackgroundColor = {0.17,0.17,0.17}
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
          local itemTypeBlock = {
            content = {
              rarityColor,
              itemConfig.categoryTitle[itemDef.category]
            },
            width = tooltipWidth,
            font = font.primary.font,
            fontSize = font.primary.fontSize
          }

          local activeAbilityBlock = nil
          if item.onActivateWhenEquipped then
            local module = itemDefinition.loadModule(item.onActivateWhenEquipped)
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
                marginBottom = blockPadding
              })
            end
          end

          local rightClickModule = itemDefinition.loadModule(item.onActivate)
          local rightClickActionBlock = (not itemState.equipped) and
            Block.Row({
              {
                content = {
                  Color.PALE_YELLOW,
                  'right-click to '..rightClickModule.tooltip(item)
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

          local baseModifiersBlock = {
            content = modParser({
              type = 'baseStatsList',
              data = item.baseModifiers
            }),
            width = tooltipWidth,
            font = font.primary.font,
            fontSize = font.primary.fontSize,
            -- background = modifierBackgroundColor,
            -- padding = blockPadding
          }
          local rows = {
            Block.Row({
              titleBlock,
              levelBlock
            }, {
              marginBottom = 6
            }),
            Block.Row({
              itemTypeBlock
            }, {
              marginBottom = 12
            }),
            Block.Row({
              baseModifiersBlock
            }, {
              marginBottom = blockPadding
            }),
            activeAbilityBlock
          }

          local functional = require 'utils.functional'
          local extraModifiersRowProps = {
            marginTop = 1
          }
          -- add extra modifiers to tooltip
          functional.forEach(item.extraModifiers, function(modifier)
            local module = itemDefinition.loadModule(modifier)
            local tooltip = module.tooltip
            if tooltip then
              local content = tooltip(item)
              table.insert(rows, Block.Row({
                {
                  content = modParser(content),
                  width = tooltipWidth,
                  font = font.primary.font,
                  fontSize = font.primary.fontSize,
                  background = modifierBackgroundColor,
                  padding = blockPadding,
                }
              }, extraModifiersRowProps))
              -- experience required help text
              local experienceRequired = modifier.props and modifier.props.experienceRequired or 0
              if (experienceRequired - item.experience) > 0 then
                table.insert(rows, Block.Row({
                  {
                    content = {
                      Color.LIME,
                      item.experience..'/'..experienceRequired..' experience required'
                    },
                    align = 'right',
                    width = tooltipWidth,
                    font = font.primary.font,
                    fontSize = font.primary.fontSize,
                    background = modifierBackgroundColor,
                    padding = blockPadding
                  },
                }, {
                  marginTop = -blockPadding
                }))
              end
            end
          end)

          table.insert(rows, rightClickActionBlock)

          self.tooltip = Block.create({
            x = posX + self.w,
            y = posY,
            background = {0,0,0,0.9},
            rows = rows,
            padding = blockPadding,
            drawOrder = function()
              return drawOrders.GUI_SLOT_TOOLTIP
            end
          }):setParent(self)
        end

        -- cleanup tooltip
        if (not self.hovered) and self.tooltip then
          self.tooltip:delete()
          self.tooltip = nil
        end
      end,
      onClick = function(self, rightClick)
        if rightClick then
          local item = getItem()
          local d = itemDefinition.getDefinition(item)
          if d and onItemActivate then
            onItemActivate(item)
          end
          return
        end
        local x, y = gridX, gridY
        local curPickedUpItem = itemPickedUp
        -- if an item hasn't already been picked up, then we're in pickup mode
        local isPickingUp = (not itemPickedUp)
        if isPickingUp then
          itemPickedUp = onItemPickupFromSlot(x, y)
        -- drop picked up item to slot
        elseif curPickedUpItem then
          local itemSwap = onItemDropToSlot(curPickedUpItem, x, y)
          itemPickedUp = itemSwap
        end
      end,
      drawOrder = function(self)
        return drawOrders.GUI_SLOT
      end,
      render = function(self)
        if self.hovered then
          love.graphics.setColor(1,1,1,0.5)
        else
          love.graphics.setColor(defaultSlotBackground)
        end
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
    }):setParent(self)

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
    }):setParent(self)
  end)
end

return setupSlotInteractions