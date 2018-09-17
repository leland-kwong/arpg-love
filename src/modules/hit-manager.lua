local PopupTextController = require 'components.popup-text'
local popupText = PopupTextController.create()
local min, max, random = math.min, math.max, math.random
local round = require 'utils.math'.round

local function rollCritChance(chance)
  if chance == 0 then
    return false
  end
  return random(1, 1/chance) == 1
end

local function adjustedDamageTaken(self, damage, lightningDamage, criticalChance, criticalMultiplier)
  local damageReductionPerArmor = 0.0001
  local damageAfterFlatReduction = damage - self:getCalculatedStat('flatPhysicalDamageReduction')
  local damageAfterArmorResistance = (damageAfterFlatReduction * self:getCalculatedStat('armor') * damageReductionPerArmor)
  local lightningDamageAfterResistance = lightningDamage - (lightningDamage * self:getCalculatedStat('lightningResist'))
  local totalDamage = damageAfterFlatReduction
    - damageAfterArmorResistance
    + lightningDamageAfterResistance
  local criticalMultiplier = rollCritChance(criticalChance) and criticalMultiplier or 0
  local totalDamageWithCrit = totalDamage + (totalDamage * criticalMultiplier)
  return round(max(0, totalDamageWithCrit)), totalDamage, criticalMultiplier, lightningDamageAfterResistance
end

-- modifiers modify properties such as `maxHealth`, `moveSpeed`, etc...
local function applyModifiers(self, newModifiers, multiplier)
  if (not newModifiers) then
    return
  end
  multiplier = multiplier or 1
  local totalModifiers = self.modifiers
  for prop, value in pairs(newModifiers) do
    local actualValue = type(value) == 'function' and value(self) or value
    totalModifiers[prop] = (totalModifiers[prop] or 0) + (actualValue * multiplier)
  end
end

-- Returns calculated stats. This should always be used when we need the stat including any modifiers.
local function getCalculatedStat(self, prop)
  -- baseProperty + modifier
  return self:getBaseStat(prop) + (self.modifiers[prop] or 0)
end

local defaultEquipmentModifiers = require'components.state.base-stat-modifiers'()

-- Returns stat including any equipment modifiers
local function getBaseStat(self, prop)
  local equipmentModifiers = self.equipmentModifiers or defaultEquipmentModifiers
  local baseStat = self[prop] or 0
  local equipmentModifierStat = equipmentModifiers[prop] or 0
  return baseStat + equipmentModifierStat
end

local function getDamageParams(self, hit)
  local dmg = (type(hit.damage) == 'table') and hit.damage or hit
  return
    self,
    dmg.damage or 0,
    dmg.lightningDamage or 0,
    min(1, hit.criticalChance or 0), -- maximum value of 1
    hit.criticalMultiplier or 0
end

--[[
  handles hits taken for a character, managing damage and property modifiers

  self [TABLE] - component instance
  dt [NUMBER] - dt from component.update
]]
local function hitManager(self, dt, onDamageTaken)
  local arePropertiesSetup = self.modifiers ~= nil
  if not arePropertiesSetup then
    self.modifiers = {}
    self.modifiersApplied = {}
    self.hits = {}
    self.getCalculatedStat = getCalculatedStat
    self.getBaseStat = getBaseStat
  end

  local hitCount = 0
  for hitId,hit in pairs(self.hits) do
    hitCount = hitCount + 1

    if onDamageTaken then
      local actualDamage, actualNonCritDamage, actualCritMultiplier, actualLightningDamage = adjustedDamageTaken(
        getDamageParams(self, hit)
      )
      onDamageTaken(
        self,
        actualDamage,
        actualNonCritDamage,
        actualCritMultiplier,
        actualLightningDamage
      )
    end

    if hit.modifiers then
      local currentModifiers = self.modifiersApplied[hitId]
      local isNewModifiers = currentModifiers ~= hit.modifiers
      -- update modifiers for the source
      if (isNewModifiers) then
        -- undo current ones first
        applyModifiers(self, currentModifiers, -1)
        self.modifiersApplied[hitId] = hit.modifiers
        applyModifiers(self, hit.modifiers)
      end
    end

    hit.duration = (hit.duration or 0) - dt
    local isEffectFinished = hit.duration <= 0
    if isEffectFinished then
      self.hits[hitId] = nil
      self.modifiersApplied[hitId] = nil
      -- remove modifiers by negating them
      applyModifiers(self, hit.modifiers, -1)
    end
  end

  return hitCount
end

return hitManager