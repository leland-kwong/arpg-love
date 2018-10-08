local itemSystem = require(require('alias').path.itemSystem)
local itemConfig = require(require('alias').path.items..'.config')
local setupChanceFunctions = require 'utils.chance'
local f = require 'utils.functional'
local clone = require 'utils.object-utils'.clone
local loadModule = require 'modules.load-module'

local rootPath = 'components.item-inventory.items.definitions'
local allItems = love.filesystem.getDirectoryItems(string.gsub(rootPath, "%.", "/"))

return function(baseItemPool)
  baseItemPool = baseItemPool or allItems

  local function generator(path)
    return function()
      return itemSystem.create(require(path))
    end
  end

  local randomBaseItem = setupChanceFunctions(
    f.map(
      baseItemPool,
      function(path)
        local filePath = rootPath..'.'..string.gsub(path, '%.lua', '')
        return {
          chance = 1,
          __call = function()
            return generator(filePath)
          end
        }
      end,
      {}
    )
  )

  local baseStatModifiers = require 'components.state.base-stat-modifiers'
  local baseMods = baseStatModifiers()
  local randomStat = setupChanceFunctions(
    f.map(
      f.keys(baseMods),
      function(modName)
        return {
          chance = 1,
          __call = function()
            return {
              modifier = modName,
              range = {1, 10}
            }
          end
        }
      end
    )
  )

  local extraModifiersByRarity = {
    [itemConfig.rarity.MAGICAL] = 2,
    [itemConfig.rarity.RARE] = 4,
  }

  local customTitles = {
    [itemConfig.rarity.NORMAL] = function(currentTitle)
      return currentTitle
    end,
    [itemConfig.rarity.MAGICAL] = function(currentTitle)
      return 'Magical '..currentTitle
    end,
    [itemConfig.rarity.RARE] = function(currentTitle)
      return 'Rare '..currentTitle
    end,
  }

  local function randomItemByRarity(rarity)
    local baseItem = randomBaseItem()()
    local fancyRandom = require 'utils.fancy-random'
    if rarity == itemConfig.rarity.MAGICAL or
      rarity == itemConfig.rarity.RARE
    then
      local numModifiers = extraModifiersByRarity[rarity]
      local modsToRoll = {}
      local numModsAdded = 0
      while numModsAdded < numModifiers do
        local statDefinition = randomStat()
        local hasStat = modsToRoll[statDefinition.modifier] ~= nil
        if (not hasStat) then
          modsToRoll[statDefinition.modifier] = statDefinition.range
          numModsAdded = numModsAdded + 1
        end
      end
      local statsModule = require(require('alias').path.items..'.modifiers.stat')
      local modifier = statsModule(modsToRoll)
      itemSystem.item.addModifier(baseItem, modifier)
    end
    itemSystem.item.setRarity(baseItem, rarity)
    local title = itemSystem.getDefinition(baseItem).title
    itemSystem.item.setCustomTitle(baseItem, customTitles[rarity](title))
    return baseItem
  end

  -- returns a random rarity
  local randomRarity = setupChanceFunctions(
    f.map(
      f.keys(itemConfig.rarity),
      function(rarityKey)
        local rarity = itemConfig.rarity[rarityKey]
        return {
          chance = itemConfig.baseDropChance[rarity],
          __call = function()
            return rarity
          end
        }
      end
    )
  )

  local function getRate(dropRate)
    return (dropRate < 1) and dropRate or 1
  end

  local socket = require 'socket'
  math.randomseed(socket.gettime())

  --[[
    {itemLevel}
    {dropRate} - out of 100%, where every 100% guarantees at least one item\
  ]]
  local function generateRandomItem(itemLevel, dropRate, minRarity, maxRarity)
    assert(type(itemLevel) == 'number')
    assert(type(dropRate) == 'number')

    local lootList = {}
    local multiplier = 100
    local randMax = 100 * multiplier

    -- if this is over 0 then that means we should roll again for a chance at more items
    while getRate(dropRate) > 0 do
      local rarity = randomRarity()
      local isValidRarity = (rarity >= minRarity) and (rarity <= maxRarity)
      if isValidRarity then
        local rand = math.random(0, randMax)
        local success = rand <= dropRate * multiplier
        if success then
          table.insert(
            lootList,
            randomItemByRarity(rarity)
          )
        end
        dropRate = dropRate - multiplier
      end
    end

    return lootList
  end

  return generateRandomItem
end