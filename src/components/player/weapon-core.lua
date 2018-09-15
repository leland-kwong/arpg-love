local Component = require 'modules.component'
local groups = require 'components.groups'
local AnimationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

local WeaponCore = {
  id = 'WEAPON_CORE',
  group = groups.all,
  muzzleFlashDuration = 0,
  recoilDuration = 0,
  recoilDurationRemaining = 0,
  drawOrder = function(self)
    return Component.get('PLAYER'):drawOrder() + 1
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

  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.PLAYER_WEAPON_MUZZLE_FLASH == msgType then
      self.muzzleFlashDuration = 0.1
      self.muzzleFlashColor = msgValue.color
    end
    if msgBus.PLAYER_WEAPON_ATTACK == msgType then
      self.recoilDuration = msgValue.attackTime or 0.1
      self.recoilDurationRemaining = self.recoilDuration
    end
  end)
end

local max = math.max
function WeaponCore.update(self, dt)
  self.recoilDurationRemaining = self.recoilDurationRemaining - dt
  self.muzzleFlashDuration = max(0, self.muzzleFlashDuration - dt)
  self.animation:update(dt / 4)
end

local halfRad = math.pi/2
local function drawMuzzleFlash(color, x, y, angle, radius)
  local r,g,b,a = Color.multiply(color)
  local weaponLength = 26
  local offsetX, offsetY = math.sin( -angle + halfRad ) * weaponLength,
    math.cos( -angle + halfRad ) * weaponLength

  love.graphics.setColor(r,g,b,a * 0.3)
  love.graphics.circle(
    'fill',
    x + offsetX,
    y + offsetY,
    radius * 1.4
  )

  love.graphics.setColor(r,g,b,1)
  love.graphics.circle(
    'fill',
    x + offsetX,
    y + offsetY,
    radius * 0.65
  )
end

function WeaponCore.draw(self)
  local state = self
  local playerRef = Component.get('PLAYER')
  if (not playerRef) then
    return
  end

  local playerX, playerY = playerRef:getPosition()
  self.facingX, self.facingY = playerRef:getProp('facingDirectionX'),
                               playerRef:getProp('facingDirectionY')
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
end

return Component.createFactory(WeaponCore)