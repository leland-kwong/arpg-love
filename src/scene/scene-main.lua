local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local Minimap = require 'components.map.minimap'
local MainMap = require 'components.map.main-map'
local SpawnerAi = require 'components.spawn.spawn-ai'
local config = require 'config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'

local gridTileTypes = {
  -- unwalkable
  [0] = {
    'wall',
    'wall-2',
    'wall-3'
  },
  -- walkable
  [1] = {
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-2',
    'floor-3'
  }
}

local MainScene = {}

function MainScene.init(self)
  local map = Map.createAdjacentRooms(4, 20)
  local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)

  local player = Player.create({
    mapGrid = map.grid
  })

  SpawnerAi.create({
    grid = map.grid,
    walkable = map.WALKABLE
  })

  Minimap.create({
    camera = camera,
    grid = map.grid,
    scale = config.scaleFactor
  })

  MainMap.create({
    camera = camera,
    grid = map.grid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = map.WALKABLE
  })
end

return groups.all.createFactory(MainScene)