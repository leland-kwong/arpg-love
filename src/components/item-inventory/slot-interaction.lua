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
    msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, true)
  end
end
msgBus.on(msgBus.MOUSE_PRESSED, handleItemDrop)

local function getSlotPosition(gridX, gridY, offsetX, offsetY, slotSize, margin)
  local posX, posY = ((gridX - 1) * slotSize) + (gridX * margin) + offsetX,
    ((gridY - 1) * slotSize) + (gridY * margin) + offsetY
  return posX, posY
end

local signHumanized = function(v)
  return v >= 0 and "+" or "-"
end

local modifierParsers = {
  attackTime = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' attack time'
    }
  end,
  cooldown = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' cooldown'
    }
  end,
  energyCost = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' energy cost'
    }
  end,
  attackTimeReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' attack time reduction'
    }
  end,
  maxEnergy = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' maximum energy'
    }
  end,
  maxHealth = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' maximum health'
    }
  end,
  healthRegeneration = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' health regeneration'
    }
  end,
  energyRegeneration = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' energy regeneration'
    }
  end,
  flatDamage = function(value)
    return {
      Color.CYAN, signHumanized(value)..value,
      Color.WHITE, ' physical damage'
    }
  end,
  weaponDamage = function(value)
    return {
      Color.CYAN, value,
      Color.WHITE, ' weapon damage'
    }
  end,
  percentDamage = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, '% weapon damage'
    }
  end,
  armor = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' armor'
    }
  end,
  moveSpeed = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' movement speed'
    }
  end,
  coldResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' cold reistance'
    }
  end,
  lightningResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' lightning resistance'
    }
  end,
  fireResist = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' fire resistance'
    }
  end,
  flatPhysicalDamageReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value,
      Color.WHITE, ' physical damage reduction'
    }
  end,
  cooldownReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' cooldown reduction'
    }
  end,
  energyCostReduction = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' energy cost reduction'
    }
  end,
  experienceMultiplier = function(value)
    return {
      Color.CYAN, signHumanized(value)..' '..value..'%',
      Color.WHITE, ' experience gain'
    }
  end
}

local function concatTable(a, b)
  if not b then
    return a
  end
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

local baseModifiers = require 'components.state.base-stat-modifiers'()
local function parseItemModifiers(item)
  local modifiers = {}
  for k,v in pairs(item.baseModifiers) do
    local parser = modifierParsers[k]
    if parser then
      local output = parser(v)
      local length = #output
      for i=1, length, 2 do
        local color = output[i]
        local str = output[i + 1]
        local isLastItem = i == length - 1
        if isLastItem then
          str = str..'\n'
        end
        table.insert(modifiers, color)
        table.insert(modifiers, str)
      end
    else
      error('no parser for property '..k)
    end
  end
  return modifiers
end

-- handles the picked up item and makes it follow the cursor
Gui.create({
  type = Gui.types.INTERACT,
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
    Gui.create({
      x = posX,
      y = posY,
      w = slotSize,
      h = slotSize,
      type = Gui.types.INTERACT,
      onUpdate = function(self)
        -- create a tooltip
        local item = getItem()
        if self.hovered and item and (not self.tooltip) then
          local Block = require 'components.gui.block'
          local itemConfig = require'components.item-inventory.items.config'
          local modParser = require 'modules.loot.item-modifier-template-parser'
          local blockPadding = 8
          local itemDef = itemDefinition.getDefinition(item)
          local rarityColor = itemConfig.rarityColor[item.rarity]
          local tooltipWidth = 250
          local modifierBackgroundColor = {0.2,0.2,0.2}
          local titleBlock = {
            content = {
              rarityColor,
              itemDef.title,
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
              item.__type
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
                  background = modifierBackgroundColor,
                  padding = blockPadding
                }
              }, {
                marginTop = 1
              })
            end
          end

          local baseModifiersBlock = {
            content = modParser({
              type = 'baseStatsList',
              data = item.baseModifiers
            }),
            width = tooltipWidth,
            font = font.primary.font,
            fontSize = font.primary.fontSize,
            background = modifierBackgroundColor,
            padding = blockPadding
          }
          local rows = {
            Block.Row({
              titleBlock,
              levelBlock
            }, {
              marginBottom = 8
            }),
            Block.Row({
              itemTypeBlock
            }, {
              marginBottom = 12
            }),
            Block.Row({
              baseModifiersBlock
            })
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
              local experienceRequired = modifier.props and modifier.props.experienceRequired
              if experienceRequired then
                table.insert(rows, Block.Row({
                  {
                    content = {
                      Color.LIME,
                      experienceRequired..' experience to unlock'
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

          table.insert(rows, activeAbilityBlock)

          self.tooltip = Block.create({
            x = posX + self.w,
            y = posY,
            background = {0,0,0,0.9},
            rows = rows,
            padding = blockPadding,
            drawOrder = function()
              return 4
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
        return 3
      end,
      render = function(self)
        if self.hovered then
          love.graphics.setColor(1,1,1,0.5)
        else
          love.graphics.setColor(0,0,0,0.5)
        end
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

        local item = getItem()
        if slotRenderer then
          slotRenderer(item, self.x, self.y, gridX, gridY, self.w, self.h)
        end

        drawItem(item, self.x, self.y, self.w)
      end
    }):setParent(self)
  end)
end

return setupSlotInteractions