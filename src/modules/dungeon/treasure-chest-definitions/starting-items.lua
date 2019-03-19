local itemSystem = require 'components.item-inventory.items.item-system'
local itemConfig = require 'components.item-inventory.items.config'
local GlobalState = require 'main.global-state'

return function()
  local playerLevel = GlobalState.gameState:get().level
  if playerLevel <= 3 then
    return {
      guaranteedItems = {
        itemSystem.create('base.augmentation-module-one'),
        itemSystem.create('base.mock-shoes')
      }
    }
  end
  return {
    itemData = {
      level = 1,
      dropRate = math.random(100, 200),
      minRarity = itemConfig.rarity.NORMAL,
      maxRarity = itemConfig.rarity.MAGICAL,
    }
  }
end