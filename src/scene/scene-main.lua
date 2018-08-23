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
local Hud = require 'components.hud.hud'
local msgBus = require 'components.msg-bus'
local HealSource = require'components.heal-source'

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
  group = groups.all,
  rootStore = rootState
}

function MainScene.init(self)
  local parent = self

  local map = Map.createAdjacentRooms(6, 20)
  local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)

  local player = Player.create({
    mapGrid = map.grid,
    rootStore = rootState
  }):setParent(parent)

  Hud.create({
    player = player,
    rootStore = rootState
  }):setParent(parent)

  msgBus.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgBus.KEY_PRESSED == msgType then
      local key = msgValue.key
      local isActive = rootState:get().activeMenu == 'INVENTORY'
      if key == config.keyboard.INVENTORY_TOGGLE then
        if not self.inventory then
          self.inventory = Inventory.create({
            rootStore = rootState,
            slots = function()
              return rootState:get().inventory
            end
          }):setParent(self)
          rootState:set('activeMenu', 'INVENTORY')
        else
          self.inventory:delete(true)
          self.inventory = nil
          rootState:set('activeMenu', false)
        end
      end
    end

    if msgBus.ENEMY_DESTROYED == msgType then
      local lootAlgorithm = require 'components.loot-generator.algorithm-1'
      msgBus.send(msgBus.GENERATE_LOOT, {msgValue.x, msgValue.y, lootAlgorithm()})
      msgBus.send(msgBus.EXPERIENCE_GAIN, msgValue.experience)
    end

    if msgBus.GENERATE_LOOT == msgType then
      local LootGenerator = require'components.loot-generator.loot-generator'
      local x, y, item = unpack(msgValue)
      LootGenerator.create({
        x = x,
        y = y,
        item = item,
        rootStore = rootState
      }):setParent(parent)
    end

    if msgBus.PLAYER_HEAL_SOURCE_ADD == msgType then
      HealSource.add(self, msgValue, rootState)
    end

    if msgBus.PLAYER_HEAL_SOURCE_REMOVE == msgType then
      HealSource.remove(self, msgValue.source)
    end

    if msgBus.PLAYER_STATS_NEW_MODIFIERS == msgType then
      local newModifiers = msgValue
      rootState:set('statModifiers', newModifiers)
    end
  end)

  local aiCount = 50
  local generated = 0
  local minPos, maxPos = 10, 60
  while generated < aiCount do
    local posX, posY = math.random(minPos, maxPos), math.random(minPos, maxPos)
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
      }):setParent(parent)
    end
  end

  Minimap.create({
    camera = camera,
    grid = map.grid,
    scale = config.scaleFactor
  }):setParent(parent)

  MainMap.create({
    camera = camera,
    grid = map.grid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE
  }):setParent(parent)
end

return Component.createFactory(MainScene)