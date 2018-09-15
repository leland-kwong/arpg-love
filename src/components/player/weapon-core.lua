local Component = require 'modules.component'
local groups = require 'components.groups'
local AnimationFactory = require 'components.animation-factory'

local WeaponCore = {
  group = groups.all,
  drawOrder = function(self)
    -- local playerRef = Component.get('PLAYER')
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
end

function WeaponCore.update(self, dt)
  self.animation:update(dt / 4)
end

function WeaponCore.draw(self)
  local state = self
  local playerRef = Component.get('PLAYER')
  if (not playerRef) then
    return
  end
  local posX, posY = playerRef:getPosition()
  local centerOffsetX, centerOffsetY = state.animation:getOffset()
  local facingX, facingY = playerRef:getProp('facingDirectionX'),
                            playerRef:getProp('facingDirectionY')
  local facingSide = facingX > 0 and 1 or -1
  local offsetX = (facingSide * -1) * 30
  local angle = (math.atan2(facingX, facingY) * -1) + (math.pi/2)

  --shadow
  love.graphics.setColor(0,0,0,0.17)
  love.graphics.draw(
    AnimationFactory.atlas,
    state.animation.sprite,
    posX,
    posY + 15,
    angle,
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
    angle,
    1,
    -- vertically flip when facing other side so the shadow is in the right position
    1 * facingSide,
    centerOffsetX, centerOffsetY
  )
end

return Component.createFactory(WeaponCore)