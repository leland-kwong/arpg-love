local setupChanceFunctions = require 'utils.chance'

return setupChanceFunctions({
  {
    chance = 1,
    prefixName = 'mindful',
    minEnergyBonus = 80,
    maxEnergyBonus = 100,
    __call = function(self, item)
      item.prefixName = self.prefixName
      item.maxEnergy = math.random(
        self.minEnergyBonus,
        self.maxEnergyBonus
      )
      return item
    end
  }
})