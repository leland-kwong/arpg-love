local PopupTextController = require 'components.popup-text'
local popupText = PopupTextController.create()

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
  return self[prop] + (equipmentModifiers[prop] or 0)
end

--[[
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

    if onDamageTaken and hit.damage then
      onDamageTaken(self, hit.damage)
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