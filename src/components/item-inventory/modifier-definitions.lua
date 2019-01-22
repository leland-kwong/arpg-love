--[[
  loot modifier definitions
]]
local Vec2 = require 'modules.brinevector'

local bucketsByModifierType = {}

local function RangeCalculator(min, max, multiplier)
  assert(type(min) == 'number', 'min must be a number')
  assert(type(max) == 'number', 'max must be a number')
  assert(type(multiplier) == 'number', 'multiplier must be a number')

  return function(rollValue)
    assert(rollValue >= 0 and rollValue <= 1, 'roll value must be between 0 and 1')
    local result = min + math.max(0, math.ceil(rollValue * (max - min + 1)) - 1)
    return result * multiplier
  end
end

return {
  cooldownReduction = {
    range = RangeCalculator(1, 5, 0.01),
  },
  increasedActionSpeed = {
    range = RangeCalculator(1, 5, 0.01)
  },
  actionPower = {
    range = RangeCalculator(5, 15, 1)
  },
  armor = {
    range = RangeCalculator(10, 100, 1)
  },
  maxHealth = {
    range = RangeCalculator(20, 50, 1)
  },
  healthRegeneration = {
    range = RangeCalculator(0.5, 1, 1)
  },
  maxEnergy = {
    range = RangeCalculator(10, 20, 1)
  },
  energyRegeneration = {
    range = RangeCalculator(0.4, 1, 1)
  },
  moveSpeed = {
    range = RangeCalculator(2, 5, 1)
  },
}