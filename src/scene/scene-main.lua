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

local function insertTestItems(rootStore)
  local item1 = require'components.item-inventory.items.definitions.mock-shoes'.create()
  local item2 = require'components.item-inventory.items.definitions.mock-shoes'.create()
  rootStore:addItemToInventory(item1, {3, 1})
  rootStore:addItemToInventory(item2, {4, 1})
  rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.mock-armor'.create()
    , {5, 1})
  rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.gpow-armor'.create()
    , {5, 2})
  rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {1, 1})
  rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {2, 1})
  rootStore:addItemToInventory(
    require'components.item-inventory.items.definitions.potion-health'.create(),
    {2, 1})
  for i=1, 99 do
    rootStore:addItemToInventory(
      require'components.item-inventory.items.definitions.potion-health'.create(),
      {2, 2})
  end
end
insertTestItems(rootState)

function MainScene.init(self)
  local parent = self

  local map = Map.createAdjacentRooms(6, 25)
  local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)

  local player = Player.create({
    mapGrid = map.grid,
  }):setParent(parent)

  Hud.create({
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
          })
          rootState:set('activeMenu', 'INVENTORY')
        else
          self.inventory:delete(true)
          self.inventory = nil
          rootState:set('activeMenu', false)
        end
      end
    end

    if msgBus.ENEMY_DESTROYED == msgType then
      local ItemPotion = require 'components.item-inventory.items.definitions.potion-health'
      msgBus.send(msgBus.GENERATE_LOOT, {msgValue.x, msgValue.y, ItemPotion.create()})
      msgBus.send(msgBus.EXPERIENCE_GAIN, msgValue.experience)
    end

    if msgBus.GENERATE_LOOT == msgType then
      local LootGenerator = require'components.item-inventory.loot-generator'
      local x, y, item = unpack(msgValue)
      LootGenerator.create({
        x = x,
        y = y,
        item = item,
        rootStore = rootState
      }):setParent(parent)
    end
  end)

  local aiCount = 50
  local generated = 0
  local minPos, maxPos = 3, 60
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