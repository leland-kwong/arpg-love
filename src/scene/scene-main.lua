local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local Minimap = require 'components.map.minimap'
local MainMap = require 'components.map.main-map'
local Inventory = require 'components.item-inventory.inventory'
local SpawnerAi = require 'components.spawn.spawn-ai'
local InventoryController = require 'components.item-inventory.controller'
local config = require 'config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local CreateStore = require 'components.state.state'
local msgBus = require 'components.msg-bus'

local rootState = CreateStore()
local inventoryController = InventoryController(rootState)

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

local MainScene = {
  group = groups.all
}

function MainScene.init(self)
  local map = Map.createAdjacentRooms(4, 20)
  local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)

  local player = Player.create({
    mapGrid = map.grid
  })

  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.KEY_RELEASED == msgType then
      local key = msgValue.key
      local isActive = rootState:get().activeMenu == 'INVENTORY'
      if key == config.keyboard.INVENTORY_TOGGLE and (not isActive) then
        local component = Inventory.create({
          rootStore = rootState,
          slots = function()
            return rootState:get().inventory
          end,
          onDisableRequest = function()
            rootState:set('activeMenu', false)
          end
        })
        rootState:set('activeMenu', 'INVENTORY')
      end
    end
  end)

  local aiCount = 5
  local generated = 0
  while generated < aiCount do
    local posX, posY = math.random(3, 60), math.random(3, 60)
    local isValidPosition = map.grid[posY][posX] == Map.WALKABLE
    if isValidPosition then
      generated = generated + 1
      SpawnerAi.create({
        grid = map.grid,
        WALKABLE = Map.WALKABLE,
        target = player,
        x = posX,
        y = posY,
        speed = 80,
        scale = 0.5 + (math.random(1, 7) / 10)
      })
    end
  end

  Minimap.create({
    camera = camera,
    grid = map.grid,
    scale = config.scaleFactor
  })

  MainMap.create({
    camera = camera,
    grid = map.grid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE
  })
end

return Component.createFactory(MainScene)