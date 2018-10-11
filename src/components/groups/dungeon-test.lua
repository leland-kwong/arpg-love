local Component = require 'modules.component'
local config = require 'config.config'
local itemConfig = require 'components.item-inventory.items.config'
local EnvironmentInteractable = require 'components.map.environment-interactable'
local clone = require 'utils.object-utils'.clone

local function randomTreasurePosition(mapGrid)
  local rows, cols = #mapGrid, #mapGrid[1]
  return math.random(10, 20) * config.gridSize,
    math.random(10, 20) * config.gridSize
end

local function addTreasureCaches(scene)
  local mapGrid = scene.mapGrid
  local treasureCacheCount = 15
  for i=1, treasureCacheCount do
    local x, y = randomTreasurePosition(mapGrid)
    local props = {
      class = 'environment',
      x = x,
      y = y,
      itemData = {
        level = 1,
        dropRate = 10,
        minRarity = itemConfig.rarity.NORMAL,
        maxRarity = itemConfig.rarity.RARE
      },
      serialize = function(self)
        return self.initialProps
      end
    }
    EnvironmentInteractable.create(props):setParent(scene)
  end
end

return {
  system = Component.newSystem({
    name = 'dungeonTest',
    onComponentEnter = function(_, c)
      addTreasureCaches(c)
    end
  })
}