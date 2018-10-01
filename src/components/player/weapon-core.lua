local Component = require 'modules.component'
local groups = require 'components.groups'
local AnimationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local iterateGrid = require 'utils.iterate-grid'
local halfRad = math.pi/2

local WeaponCore = {
  id = 'WEAPON_CORE',
  group = groups.all,
  muzzleFlashDuration = 0,
  recoilDuration = 0,
  recoilDurationRemaining = 0,
  drawOrder = function(self)
    -- adjust draw order based on the y-facing direction
    local config = require 'config.config'
    local offsetY = math.floor(self.facingY) * self.group.drawLayersPerGridCell
    return Component.get('PLAYER'):drawOrder() + 1 + offsetY
  end
}

function WeaponCore.init(self)
  local frames = {}
  for i=0, 15 do
    table.insert(frames, 'pod-one-'..i)
  end
  for i=15, 0, -1 do
    table.insert(frames, 'pod-one-'..i)
  end
  self.animation = AnimationFactory:new(frames)

  self.listeners = {
    msgBus.on(msgBus.PLAYER_WEAPON_ATTACK, function(msgValue)
      self.recoilDuration = msgValue.attackTime or 0.1
      self.recoilDurationRemaining = self.recoilDuration
    end),
    msgBus.on(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, function(msgValue)
      self.muzzleFlashDuration = 0.1
      self.muzzleFlashColor = msgValue.color
      return msgValue
    end)
  }
end

local max = math.max
function WeaponCore.update(self, dt)
  self.recoilDurationRemaining = self.recoilDurationRemaining - dt
  self.muzzleFlashDuration = max(0, self.muzzleFlashDuration - dt)
  if self.renderAttachmentAnimation then
    self.renderAttachmentAnimation:update(
      dt * self.renderAttachmentAnimationSpeed
    )
  end
  self.animation:update(dt / 4)

  local playerRef = Component.get('PLAYER')
  self.facingX, self.facingY = playerRef:getProp('facingDirectionX'),
                               playerRef:getProp('facingDirectionY')
end

local function drawMuzzleFlash(color, x, y, angle, radius)
  local r,g,b,a = Color.multiply(color)
  local weaponLength = 26
  local offsetX, offsetY = math.sin( -angle + halfRad ) * weaponLength,
    math.cos( -angle + halfRad ) * weaponLength

  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('add')

  love.graphics.setColor(r,g,b,a * 0.3)
  love.graphics.circle(
    'fill',
    x + offsetX,
    y + offsetY,
    radius * 1.4
  )

  love.graphics.setColor(r,g,b,0.6)
  love.graphics.circle(
    'fill',
    x + offsetX,
    y + offsetY,
    radius * 0.65
  )

  love.graphics.setBlendMode(oBlendMode)
end

local function drawEquipment(equipmentAnimation, x, y, angle)
  -- if (not self.renderAttachmentAnimation) then
  --   return
  -- end
  local weaponLength = 26
  local spriteOffsetX, spriteOffsetY = equipmentAnimation:getSourceOffset()
  local offsetX, offsetY = math.sin( -angle + halfRad ) * (weaponLength),
    math.cos( -angle + halfRad ) * (weaponLength)

  love.graphics.setColor(0,0,0,0.17)
  love.graphics.draw(
    AnimationFactory.atlas,
    equipmentAnimation.sprite,
    x + offsetX,
    y + offsetY + 15,
    angle,
    1, 1,
    spriteOffsetX,
    spriteOffsetY
  )

  love.graphics.setColor(1,1,1)
  love.graphics.draw(
    AnimationFactory.atlas,
    equipmentAnimation.sprite,
    x + offsetX,
    y + offsetY,
    angle,
    1, 1,
    spriteOffsetX,
    spriteOffsetY
  )
end

function WeaponCore.draw(self)
  local state = self
  local playerRef = Component.get('PLAYER')
  if (not playerRef) then
    return
  end

  local playerX, playerY = playerRef:getPosition()
  self.angle = (math.atan2(self.facingX, self.facingY) * -1) + (math.pi/2)

  local recoilMaxDistance = -4
  local recoilDistance = self.recoilDurationRemaining > 0
    and (self.recoilDurationRemaining/self.recoilDuration * recoilMaxDistance)
    or 0
  local posX = playerX + recoilDistance * math.sin(-self.angle + halfRad)
  local posY = playerY + recoilDistance * math.cos(-self.angle + halfRad)

  local centerOffsetX, centerOffsetY = state.animation:getOffset()
  local facingSide = self.facingX > 0 and 1 or -1
  local offsetX = (facingSide * -1) * 30

  --shadow
  love.graphics.setColor(0,0,0,0.17)
  love.graphics.draw(
    AnimationFactory.atlas,
    state.animation.sprite,
    posX,
    posY + 15,
    self.angle,
    1,
    -- vertically flip when facing other side so the shadow is in the right position
    (1 * facingSide) / 2,
    centerOffsetX, centerOffsetY
  )

  love.graphics.setColor(1,1,1)
  -- actual graphic
  love.graphics.draw(
    AnimationFactory.atlas,
    state.animation.sprite,
    posX,
    posY,
    self.angle,
    1,
    -- vertically flip when facing other side so the shadow is in the right position
    1 * facingSide,
    centerOffsetX, centerOffsetY
  )

  if (self.muzzleFlashDuration > 0) then
    drawMuzzleFlash(
      self.muzzleFlashColor,
      posX,
      posY,
      self.angle,
      8
    )
  end

  local rootStore = msgBus.send(msgBus.GAME_STATE_GET)
  if rootStore then
    local gameState = rootStore:get()
    iterateGrid(gameState.equipment, function(item)
      local itemDef = require 'components.item-inventory.items.item-system'
      local definition = itemDef.getDefinition(item)
      local spriteName = definition and definition.renderAnimation
      if spriteName then
        local animation = AnimationFactory:newStaticSprite(spriteName)
        drawEquipment(animation, posX, posY, self.angle)
      end
    end)
  end
end

function WeaponCore.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(WeaponCore)