local Component = require 'modules.component'
local RandomItem = require 'components.loot-generator.algorithm-1'
local itemConfig = require(require('alias').path.items..'.config')
local config = require 'config.config'
local Map = require 'modules.map-generator.index'

local lootAlgorithm = RandomItem()

local function generateLoot(c, item, delay)
  local tick = require 'utils.tick'
  tick.delay(function()
    local LootGenerator = require'components.loot-generator.loot-generator'
    LootGenerator.create({
      x = c.x,
      y = c.y,
      item = item,
    })
  end, delay)
end

local EMPTY = {}

return {
  system = Component.newSystem({
    name = 'loot',
    onComponentEnter = function(_, c)
      local iData = c.itemData
      local delayBetweenDrops = c.delay or 0.1

      for i=1, #(c.guaranteedItems or EMPTY) do
        generateLoot(c, c.guaranteedItems[i], (i-1) * delayBetweenDrops)
      end

      local items = lootAlgorithm(iData.level, iData.dropRate, iData.minRarity, iData.maxRarity)
      for i=1, #items do
        generateLoot(c, items[i], (i-1) * delayBetweenDrops)
      end
    end
  })
}