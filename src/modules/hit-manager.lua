local PopupTextController = require 'components.popup-text'
local popupText = PopupTextController.create()
local min, max, random = math.min, math.max, math.random
local round = require 'utils.math'.round
local Object = require 'utils.object-utils'

local function rollCritChance(chance)
  if chance == 0 then
    return false
  end
  return random(1, 1/chance) == 1
end

local F = require 'utils.functional'
local elementalCalculators = F.reduce({'lightning', 'cold', 'fire'}, function(calcFns, element)
  local damageProp = element..'Damage'
  local resistProp = element..'Resist'
  calcFns[element] = function(stats, hit)
    local damage = hit[damageProp]
    local resistance = hit[resistProp]
    return damage - (damage * stats:get(resistProp))
  end
  return calcFns
end, {})

local function adjustedDamageTaken(stats, hit)
  local damage = hit.damage
  local lightningDamage = hit.lightningDamage
  local coldDamage = hit.coldDamage
  local criticalChance = min(1, hit.criticalChance or 0)
  local criticalMultiplier = hit.criticalMultiplier or 0

  local damageReductionPerArmor = 0.0001
  local damageAfterFlatReduction = math.max(0, damage - stats:get('physicalReduction'))
  local reducedDamageFromArmorResistance = (damageAfterFlatReduction * stats:get('armor') * damageReductionPerArmor)
  local actualLightningDamage, actualColdDamage =
    elementalCalculators['lightning'](stats, hit),
    elementalCalculators['cold'](stats, hit)
  local totalDamage = damageAfterFlatReduction
    - reducedDamageFromArmorResistance
    + actualLightningDamage
    + actualColdDamage
  local criticalMultiplier = rollCritChance(criticalChance) and criticalMultiplier or 0
  local totalDamageWithCrit = totalDamage + (totalDamage * criticalMultiplier)
  return round(max(0, totalDamageWithCrit)),
    totalDamage,
    criticalMultiplier,
    actualLightningDamage,
    actualColdDamage
end

-- modifiers modify properties such as `maxHealth`, `moveSpeed`, etc...
local function applyModifiers(self, newModifiers, multiplier)
  if (not newModifiers) then
    return
  end
  multiplier = multiplier or 1
  for prop, value in pairs(newModifiers) do
    local actualValue = type(value) == 'function' and value(self) or value
    self.stats:add(prop, actualValue * multiplier)
  end
end

--[[
  handles hits taken for a character, managing damage and property modifiers

  self [TABLE] - component instance
  dt [NUMBER] - dt from component.update
]]
local function hitManager(_, self, dt, onDamageTaken)
  local hitCount = 0
  for hitId,hit in pairs(self.hitData) do
    hitCount = hitCount + 1

    if onDamageTaken then
      local actualDamage,
        actualNonCritDamage,
        actualCritMultiplier,
        actualLightningDamage,
        actualColdDamage = adjustedDamageTaken(self.stats, hit)
      onDamageTaken(
        self,
        actualDamage,
        actualNonCritDamage,
        actualCritMultiplier,
        actualLightningDamage,
        actualColdDamage
      )
    end

    if hit.modifiers then
      local currentModifiers = self.modifiersApplied[hitId]
      local isNewModifiers = currentModifiers ~= hit.modifiers
      -- update modifiers for the source
      if (isNewModifiers) then
        self.modifiersApplied[hitId] = hit.modifiers
      end
    end

    applyModifiers(self, hit.modifiers)

    hit.duration = (hit.duration or 0) - dt
    local isEffectFinished = hit.duration <= 0
    if isEffectFinished then
      self.hitData[hitId] = nil
      self.modifiersApplied[hitId] = nil
    end
  end

  self.hitCount = hitCount
  return hitCount
end

return setmetatable({
  setup = function(component)
    component.modifiersApplied = {}
    component.hitData = {}
  end,
}, {
  __call = hitManager
})