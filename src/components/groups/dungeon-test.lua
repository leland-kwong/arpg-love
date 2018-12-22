local Component = require 'modules.component'
local config = require 'config.config'
local itemConfig = require 'components.item-inventory.items.config'
local EnvironmentInteractable = require 'components.map.environment-interactable'
local clone = require 'utils.object-utils'.clone
local Map = require 'modules.map-generator.index'
local Grid = require 'utils.grid'

local function randomTreasurePosition(mapGrid, occupiedPositions)
  local rows, cols = #mapGrid, #mapGrid[1]
  local gridX, gridY = math.random(1, rows),
    math.random(1, cols)
  local x, y = gridX * config.gridSize, gridY * config.gridSize
  if (
    (not Grid.get(occupiedPositions, x, y)) and
    Map.WALKABLE(Grid.get(mapGrid, gridX, gridY))
  ) then
    return x, y
  end
  return randomTreasurePosition(mapGrid, occupiedPositions)
end

local function addTreasureCaches(scene)
  local mapGrid = scene.mapGrid
  local treasureCacheCount = 100
  local occupiedPositions = {}
  for i=1, treasureCacheCount do
    local x, y = randomTreasurePosition(mapGrid, occupiedPositions)
    Grid.set(occupiedPositions, x, y, true)
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
      end,
      onDestroyStart = function()
        local Sound = require 'components.sound'
        Sound.playEffect('treasure-cache-demolish.wav')
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