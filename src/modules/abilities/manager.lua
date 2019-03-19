local config = require 'config.config'

local Ability = {
  isManager = true
}
Ability.__index = Ability

function Ability.new(ability)
  local manager = {
    ability = ability.isManager and ability.ability or ability,
    cooldown = 0,
    -- the ability will not be ready if the ability is still recovering
    isRecovering = false,
    state = {}
  }
  setmetatable(manager, Ability)
  return manager
end

function Ability:update(caster, dt)
  self.cooldown = self.cooldown - dt
  local update = self.ability.update
  -- ability has an animation, so we'll get the `isReady` status from the update cycle
  if update then
    self.isRecovering = update(caster, self.state, dt)
  -- ability has no animation, so it is always ready
  else
    self.isRecovering = false
  end
end

function Ability:use(caster, targetX, targetY, distFromTarget)
  local ability = self.ability
  local isCoolingDown = self.cooldown > 0
  local isInAbilityRange = distFromTarget <= (ability.range * config.gridSize)
  local canUse = (not self.isRecovering)
    and isInAbilityRange
    and (not isCoolingDown)
  if (canUse) then
    self.cooldown = ability.cooldown
    self.isRecovering = true
    ability.use(caster, self.state, targetX, targetY, distFromTarget)
  end
end

return Ability