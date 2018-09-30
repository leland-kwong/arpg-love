local itemsPath = 'components.item-inventory.items.definitions.'
local setupChanceFunctions = require 'utils.chance'

local function generator(path)
  return function()
    return require(path).create()
  end
end

local lootPool = setupChanceFunctions({
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

local function getRate(dropRate)
  return (dropRate < 1) and dropRate or 1
end

local socket = require 'socket'
math.randomseed(socket.gettime())

local function generateRandomItem(itemLevel, dropRate)
  assert(type(itemLevel) == 'number')
  assert(type(dropRate) == 'number')

  local lootList = {}
  local multiplier = 100
  local randMax = 100 * multiplier

  -- if this is over 0 then that means we should roll again for a chance at more items
  while getRate(dropRate) > 0 do
    local rand = math.random(0, randMax)
    local success = rand <= dropRate * multiplier
    if success then
      table.insert(lootList, lootPool())
    end
    dropRate = dropRate - multiplier
  end

  return lootList
end

return generateRandomItem