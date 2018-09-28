local config = require 'config.config'

local Ability = {}
Ability.__index = Ability

function Ability.new(ability)
  local manager = {
    ability = ability,
    cooldown = 0,
    state = {}
  }
  setmetatable(manager, Ability)
  return manager
end

function Ability:update(caster, dt)
  self.cooldown = self.cooldown - dt
  local update = self.ability.update
  if update then
    update(caster, self.state, dt)
  end
end

function Ability:use(caster, targetX, targetY, distFromTarget)
  local ability = self.ability
  local canUse = distFromTarget <= (ability.range * config.gridSize)
  local isAbilityReady = self.cooldown <= 0
  local attackTime = 0
  if (canUse and isAbilityReady) then
    attackTime = ability.attackTime
    self.cooldown = ability.cooldown
    ability.use(caster, self.state, targetX, targetY, distFromTarget)
  end
  return attackTime
end

return Ability