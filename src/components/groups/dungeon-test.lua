local Component = require 'modules.component'
local config = require 'config.config'
local EnvironmentInteractable = require 'components.map.environment-interactable'

local function randomTreasurePosition(mapGrid)
  local rows, cols = #mapGrid, #mapGrid[1]
  return math.random(10, cols) * config.gridSize,
    math.random(10, rows) * config.gridSize
end

local function addTreasureCaches(scene)
  local mapGrid = scene.mapGrid
  local treasureCacheCount = 15
  for i=1, treasureCacheCount do
    local x, y = randomTreasurePosition(mapGrid)
    EnvironmentInteractable.create({
      x = x,
      y = y
    }):setParent(scene)
  end
end

return {
  system = Component.newSystem({
    onComponentEnter = function(_, c)
      addTreasureCaches(c)
    end
  })
}