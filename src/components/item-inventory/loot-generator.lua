local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local groups = require 'components.groups'
local ItemPotion = require 'components.item-inventory.items.definitions.potion-health'
local itemDefs = require 'components.item-inventory.items.item-definitions'
local Gui = require 'components.gui.gui'
local camera = require 'components.camera'
local CreateStore = require 'components.state.state'
local msgBus = require 'components.msg-bus'
local tick = require 'utils.tick'

local LootGenerator = {
  group = groups.gui,
  rootStore = CreateStore,
  -- item to generate
  item = nil
}

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = AnimationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)
shader:send('outline_color', outlineColor)

local COLLISION_FLOOR_ITEM_TYPE = 'floorItem'
local function collisionFilter(item, other)
  if other.group == COLLISION_FLOOR_ITEM_TYPE or other.group == 'wall' then
    return 'slide'
  end
  return false
end

function LootGenerator.init(self)
  local _self = self
  local rootStore = self.rootStore
  local screenX, screenY = self.x, self.y
  local item = self.item or ItemPotion.create()

  local animation = AnimationFactory:new({
    itemDefs.getDefinition(item).sprite
  })

  local sx, sy, sw, sh = animation.sprite:getViewport()

  Gui.create({
    group = groups.all,
    x = screenX,
    y = screenY,
    w = sw,
    h = sh,
    collisionGroup = COLLISION_FLOOR_ITEM_TYPE,
    isNewlyGenerated = true,
    getMousePosition = function()
      return camera:getMousePosition()
    end,
    onPointerEnter = function()
      msgBus.send(msgBus.ITEM_HOVERED, true)
    end,
    onPointerLeave = function()
      msgBus.send(msgBus.ITEM_HOVERED, false)
    end,
    pickup = function()
      if self.pickupPending then
        return
      end
      rootStore:addItemToInventory(item)
      self:delete(true)
      -- --[[
      --   Add a slight delay for ITEM_PICKUP_SUCCESS since we disable the player's click events
      --   after pickup to prevent attack on pickup.
      -- ]]
      self.pickupPending = tick.delay(function()
        msgBus.send(msgBus.ITEM_PICKUP_SUCCESS)
      end, 0.2)
    end,
    onClick = function(self)
      self.selected = true
    end,
    onUpdate = function(self, dt)
      if self.isNewlyGenerated then
        local actualX, actualY, cols, len = self.colObj:move(self.x, self.y, collisionFilter)
        if len > 0 then
          self.x = actualX
          self.y = actualY
          self.isNewlyGenerated = false
        end
      end

      if self.selected then
        if love.mouse.isDown(1) then
          -- self.selected = true
          msgBus.send(msgBus.ITEM_PICKUP, self)
        elseif not self.pickupPending then
          msgBus.send(msgBus.ITEM_PICKUP_CANCEL)
          self.selected = false
        end
      end
    end,
    draw = function(self)
      -- draw item shadow
      love.graphics.setColor(0,0,0,.3)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y + (self.h * 1.25),
        0,
        1, -0.5
      )

      if self.hovered then
        love.graphics.setShader(shader)
      end

      -- draw item
      love.graphics.setColor(1,1,1)
      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x, self.y
      )

      if self.hovered then
        love.graphics.setShader()
      end
    end
  }):setParent(self)
end

return Component.createFactory(LootGenerator)