local setupChanceFunctions = require 'utils.chance'

-- enhances the ai's base stats and abilities with new random powers
local addRandomPropery = setupChanceFunctions({
  {
    type = 'extra fast',
    chance = 1,
    lowerPercentSpeed = 1,
    upperPercentSpeed = 2,
    __call = function(self, ai)
      local moveSpeedBonus = math.random(self.lowerPercentSpeed, self.upperPercentSpeed) / 2
      local modType = 'extra fast'
      return self.type, 'moveSpeed', ai.moveSpeed + (ai.moveSpeed * moveSpeedBonus)
    end
  }
})

local generateRandomRarity = setupChanceFunctions({
  {
    type = 'NORMAL',
    chance = 15,
    __call = function(self, ai)
      return ai
    end
  },
  {
    type = 'MAGICAL',
    chance = 4,
    outlineColor = {0.5, 0.5, 1, 1},
    __call = function(self, ai)
      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 2)
        :set('experience', ai.experience * 2.5)
    end
  },
  {
    type = 'RARE',
    chance = 2,
    outlineColor = {0.8, 0.8, 0, 1},
    __call = function(self, ai)
      local modType, prop, value = addRandomPropery(ai)
      ai:set(prop, value)
      table.insert(ai.dataSheet.properties, modType)

      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 5)
        :set('experience', ai.experience * 6)
    end
  },
})

return function(ai)
  return generateRandomRarity(ai)
end