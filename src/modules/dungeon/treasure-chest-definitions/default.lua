local itemSystem = require 'components.item-inventory.items.item-system'
local itemConfig = require 'components.item-inventory.items.config'

return function()
  return {
    itemData = {
      level = 1,
      dropRate = math.random(200, 300),
      minRarity = itemConfig.rarity.NORMAL,
      maxRarity = itemConfig.rarity.LEGENDARY,
    }
  }
end