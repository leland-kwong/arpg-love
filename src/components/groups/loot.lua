local Component = require 'modules.component'
local RandomItem = require 'components.loot-generator.algorithm-1'
local itemConfig = require(require('alias').path.items..'.config')
local config = require 'config.config'
local Map = require 'modules.map-generator.index'

local lootAlgorithm = RandomItem()

local function generateLoot(c, item)
  local LootGenerator = require'components.loot-generator.loot-generator'
  LootGenerator.create({
    x = c.x,
    y = c.y,
    item = item,
  })
end

return {
  system = Component.newSystem({
    name = 'loot',
    onComponentEnter = function(_, c)
      local iData = c.itemData
      local items = lootAlgorithm(iData.level, iData.dropRate, iData.minRarity, iData.maxRarity)
      for i=1, #items do
        generateLoot(c, items[i])
      end
    end
  })
}