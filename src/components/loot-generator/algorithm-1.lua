local setupChanceFunctions = require 'utils.chance'
local f = require 'utils.functional'
local clone = require 'utils.object-utils'.clone
local loadModule = require 'modules.load-module'

local rootPath = 'components.item-inventory.items.definitions'

-- local itemModuleFiles = love.filesystem.getDirectoryItems(string.gsub(rootPath, "%.", "/"))

local function generator(path)
  return function()
    return require(path).create()
  end
end

-- local itemConfig = require 'components.item-inventory.items.config'
-- local function ensureTable(table, key)
--   table[key] = table[key] or {}
--   return table[key]
-- end
-- local chancesByRarity = f.reduce(itemModuleFiles, function(itemsByRarity, filename)
--   local itemDef = loadModule(rootPath, filename)
--   local rarity = itemDef.rarity
--   local dropPercentChance = itemDef.baseDropChance
--   local itemList = ensureTable(itemsByRarity, rarity)
--   table.insert(itemList, {
--     chance = 1,
--     __call = function()
--       return itemDef.create()
--     end
--   })

--   -- setup roll chance for both magical and rare items by enhancing a normal item
--   if rarity == itemConfig.rarity.NORMAL then
--     local MAGICAL = itemConfig.rarity.MAGICAL
--     local magicalList = ensureTable(itemsByRarity, MAGICAL)
--     table.insert(magicalList, {
--       chance = 1,
--       __call = function()
--         -- add magical modifiers
--         local item = itemDef.create()
--         item.rarity = MAGICAL
--         return item
--       end
--     })

--     local RARE = itemConfig.rarity.RARE
--     local rareList = ensureTable(itemsByRarity, RARE)
--     table.insert(rareList, {
--       chance = 1,
--       __call = function()
--         -- add rare modifiers
--         local item = itemDef.create()
--         item.rarity = RARE
--         return item
--       end
--     })
--   end

--   return itemsByRarity
-- end, {})

-- local randomItemByRarity = f.reduce(
--   f.keys(chancesByRarity),
--   function(randomRoller, rarity)
--     randomRoller[rarity] = setupChanceFunctions(chancesByRarity[rarity])
--     return randomRoller
--   end,
--   {}
-- )

-- -- returns a random item by rarity chance
-- local randomRarity = setupChanceFunctions(
--   f.map(
--     f.keys(chancesByRarity),
--     function(rarity)
--       return {
--         chance = itemConfig.baseDropChance[rarity],
--         __call = function()
--           return rarity
--         end
--       }
--     end
--   )
-- )

-- local function getRate(dropRate)
--   return (dropRate < 1) and dropRate or 1
-- end

local socket = require 'socket'
math.randomseed(socket.gettime())

local function generateRandomItem(itemLevel, dropRate, minRarity, maxRarity)
  assert(type(itemLevel) == 'number')
  assert(type(dropRate) == 'number')

  local lootList = {}
  local multiplier = 100
  local randMax = 100 * multiplier

  -- if this is over 0 then that means we should roll again for a chance at more items
  -- while getRate(dropRate) > 0 do
  --   local rarity = randomRarity()
  --   local isValidRarity = (rarity >= minRarity) and (rarity <= maxRarity)
  --   if isValidRarity then
  --     local rand = math.random(0, randMax)
  --     local success = rand <= dropRate * multiplier
  --     if success then
  --       table.insert(
  --         lootList,
  --         randomItemByRarity[rarity]()
  --       )
  --     end
  --     dropRate = dropRate - multiplier
  --   end
  -- end

  return lootList
end

return generateRandomItem