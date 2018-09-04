local PopupTextController = require 'components.popup-text'
local popupText = PopupTextController.create()

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
  end

  local hitCount = 0
  for hitId,hit in pairs(self.hits) do
    hitCount = hitCount + 1

    if hit.damage and onDamageTaken then
      onDamageTaken(self, hit.damage)
    end

    if hit.modifiers then
      if (not self.modifiersApplied[hitId]) then
        self.modifiersApplied[hitId] = true
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