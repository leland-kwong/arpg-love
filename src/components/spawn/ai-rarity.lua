local setupChanceFunctions = require 'utils.chance'

local generateRandomProperty = setupChanceFunctions({
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
    chance = 3,
    __call = function(self, ai)
      return ai
    end
  },
  {
    type = 'MAGICAL',
    chance = 3,
    outlineColor = {0.5, 0.5, 1, 1},
    __call = function(self, ai)
      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 2)
        :set('experience', ai.experience * 2)
    end
  },
  {
    type = 'RARE',
    chance = 3,
    outlineColor = {0.8, 0.8, 0, 1},
    __call = function(self, ai)
      local modType, prop, value = generateRandomProperty(ai)
      ai:set(prop, value)
      table.insert(ai.dataSheet.properties, modType)

      return ai:set('outlineColor', self.outlineColor)
        :set('maxHealth', ai.maxHealth * 5)
        :set('experience', ai.experience * 5)
    end
  },
})

return function(ai)
  return generateRandomRarity(ai)
end