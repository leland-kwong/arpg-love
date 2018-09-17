local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Enum = require 'utils.enum'

local state = Enum({
  'SHIELD_HIT',
  'SHIELD_UP',
  'SHIELD_DOWN'
})

local ForceField = {
  group = groups.all,
  size = 30,
  shieldHealth = 0,
  maxShieldHealth = 100,
  unhitDuration = 0,
  unhitDurationRequirement = 2,
  state = state.SHIELD_DOWN
}

local function hitAnimation()
  local frame = 0
  local animationLength = 3
  while frame < animationLength do
    frame = frame + 1
    coroutine.yield(false)
  end
  coroutine.yield(true)
end

function ForceField.init(self)
  -- body
  msgBus.addReducer(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if (msgBus.PLAYER_HIT_RECEIVED == msgType) then
      self.unhitDuration = 0
      local damageAfterAbsorption = math.max(0, msgValue - self.shieldHealth)
      -- modify shield health
      self.shieldHealth = math.max(0, self.shieldHealth - msgValue)

      if self.shieldHealth > 0 then
        self.hitAnimation = coroutine.wrap(hitAnimation)
      end
      return damageAfterAbsorption
    end

    return msgValue
  end)
end

function ForceField.update(self, dt)
  self.unhitDuration = self.unhitDuration + dt
  self:setDrawDisabled(self.shieldHealth <= 0)

  local hasShield = self.shieldHealth > 0
  local shouldEnableShield = self.unhitDuration >= self.unhitDurationRequirement
  if shouldEnableShield then
    self.shieldHealth = self.maxShieldHealth
    self.state = state.SHIELD_UP
  end

  if self.hitAnimation then
    local done = self.hitAnimation()
    if done then
      self.hitAnimation = nil
    end
  end
  self.state = self.hitAnimation and state.SHIELD_HIT or state.SHIELD_UP
end

function ForceField.draw(self)
  local r,g,b = 0.3, 0.5, 1
  if self.state == state.SHIELD_HIT then
    love.graphics.setColor(1,1,1,0.6)
  else
    love.graphics.setColor(r, g, b, 0.05)
  end
  love.graphics.circle('fill', self.x, self.y, self.size)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(r, g, b, 0.3)
  love.graphics.circle('line', self.x, self.y, self.size)
end

return Component.createFactory(ForceField)