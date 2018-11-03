local itemSystem = require(require('alias').path.itemSystem)
local itemConfig = require(require('alias').path.items..'.config')
local setupChanceFunctions = require 'utils.chance'
local f = require 'utils.functional'
local clone = require 'utils.object-utils'.clone


return function()
  local function generator(path)
    return function()
      return itemSystem.create(require(path))
    end
  end

  local baseItemsRootPath = 'components.item-inventory.items.definitions.base'
  local baseItemPool = love.filesystem.getDirectoryItems(string.gsub(baseItemsRootPath, "%.", "/"))
  local randomBaseItem = setupChanceFunctions(
    f.map(
      baseItemPool,
      function(path)
        local filePath = baseItemsRootPath..'.'..string.gsub(path, '%.lua', '')
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

  local legendaryItemsRootPath = 'components.item-inventory.items.definitions.legendary'
  local legendaryItemPool = love.filesystem.getDirectoryItems(string.gsub(legendaryItemsRootPath, "%.", "/"))
  local randomLegendaryItem = setupChanceFunctions(
    f.map(
      legendaryItemPool,
      function(path)
        local filePath = legendaryItemsRootPath..'.'..string.gsub(path, '%.lua', '')
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

  -- generates random stats
  local baseStatModifiers = require 'components.state.base-stat-modifiers'
  local modRanges = require 'components.item-inventory.modifier-definitions'
  local randomStat = setupChanceFunctions(
    f.map(
      f.keys(modRanges),
      function(modName)
        return {
          chance = 1,
          __call = function()
            local round = require 'utils.math'.round
            return {
              modifier = modName,
              --[[
                Store the value as a float between 0 and 1.
                We will use this later to calculate the actual values based on their min-max range.
              ]]
              range = round(math.random(), 2)
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
    local isMagicalOrRare = rarity == itemConfig.rarity.MAGICAL or
      rarity == itemConfig.rarity.RARE
    if isMagicalOrRare then
      local baseItem = randomBaseItem()()
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
      itemSystem.item.setRarity(baseItem, rarity)
      local title = itemSystem.getDefinition(baseItem).title
      itemSystem.item.setCustomTitle(baseItem, customTitles[rarity](title))
      return baseItem
    end

    if (itemConfig.rarity.LEGENDARY == rarity) then
      return randomLegendaryItem()()
    end

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
    {dropRate} - out of 100%, where every 100% guarantees at least one item
  ]]
  local function generateRandomItem(itemLevel, dropRate, minRarity, maxRarity)
    assert(type(itemLevel) == 'number')
    assert(type(dropRate) == 'number')
    assert(type(minRarity) == 'number' and type(maxRarity) == 'number')

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