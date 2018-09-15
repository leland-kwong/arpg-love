local Component = require 'modules.component'
local groups = require 'components.groups'
local AnimationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'

local WeaponCore = {
  id = 'WEAPON_CORE',
  group = groups.all,
  muzzleFlashDuration = 0,
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
    if msgBus.SHOW_MUZZLE_FLASH == msgType then
      self.muzzleFlashDuration = 0.1
      self.muzzleFlashColor = msgValue.color
    end
  end)
end

function WeaponCore.update(self, dt)
  self.muzzleFlashDuration = self.muzzleFlashDuration - dt
  self.animation:update(dt / 4)
end

local function drawMuzzleFlash(color, x, y, angle, radius)
  local r,g,b,a = Color.multiply(color)
  local halfRad = math.pi/2
  local weaponLength = 26

  love.graphics.setColor(r,g,b,a * 0.3)
  love.graphics.circle(
    'fill',
    x + math.sin( -angle + halfRad ) * weaponLength,
    y + math.cos( -angle + halfRad ) * weaponLength,
    radius
  )

  love.graphics.setColor(r,g,b,1)
  love.graphics.circle(
    'fill',
    x + math.sin( -angle + halfRad ) * weaponLength,
    y + math.cos( -angle + halfRad ) * weaponLength,
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

  local centerOffsetX, centerOffsetY = state.animation:getOffset()
  local facingSide = self.facingX > 0 and 1 or -1
  local offsetX = (facingSide * -1) * 30

  --shadow
  love.graphics.setColor(0,0,0,0.17)
  love.graphics.draw(
    AnimationFactory.atlas,
    state.animation.sprite,
    playerX,
    playerY + 15,
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
    playerX,
    playerY,
    self.angle,
    1,
    -- vertically flip when facing other side so the shadow is in the right position
    1 * facingSide,
    centerOffsetX, centerOffsetY
  )

  if (self.muzzleFlashDuration > 0) then
    drawMuzzleFlash(
      self.muzzleFlashColor,
      playerX,
      playerY,
      self.angle,
      9
    )
  end
end

return Component.createFactory(WeaponCore)