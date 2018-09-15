local itemsPath = 'components.item-inventory.items.definitions.'
local setupChanceFunctions = require 'utils.chance'

local function generator(path)
  return function()
    return require(path).create()
  end
end

local lootPool = setupChanceFunctions({
  {
    chance = 20,
    __call = function()
      return nil
    end
  },
  {
    chance = 3,
    __call = generator(itemsPath..'pod-module-fireball')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'mock-shoes')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'gpow-armor')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'potion-health')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'potion-energy')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'lightning-rod')
  },
  {
    chance = 3,
    __call = generator(itemsPath..'pod-module-slow-time')
  }
})

return lootPool