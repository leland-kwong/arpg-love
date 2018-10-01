local Component = require 'modules.component'
local config = require 'config.config'
local EnvironmentInteractable = require 'components.map.environment-interactable'

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
    EnvironmentInteractable.create({
      x = x,
      y = y,
      itemData = {
        level = 1,
        dropRate = 20
      },
    }):setParent(scene)
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