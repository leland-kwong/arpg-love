local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local Minimap = require 'components.map.minimap'
local MainMap = require 'components.map.main-map'
local Inventory = require 'components.item-inventory.inventory'
local SpawnerAi = require 'components.spawn.spawn-ai'
local InventoryController = require 'components.item-inventory.controller'
local config = require 'config.config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local CreateStore = require 'components.state.state'
local Hud = require 'components.hud.hud'
local fileSystem = require 'modules.file-system'
local msgBus = require 'components.msg-bus'
local HealSource = require 'components.heal-source'
local tick = require 'utils.tick'

local function setupTileTypes(types)
  local list = {}
  for i=1, #types do
    local t = types[i]
    for j=1, t.chance do
      table.insert(list, t.type)
    end
  end
  return list
end

local gridTileTypes = {
  -- unwalkable
  [0] = setupTileTypes({
    {
      type = 'wall-1',
      chance = 10
    },
    {
      type = 'wall-2',
      chance = 10
    },
    {
      type = 'wall-3',
      chance = 20
    },
    {
      type = 'wall-4',
      chance = 40
    },
    {
      type = 'wall-5',
      chance = 2
    },
    {
      type = 'wall-6',
      chance = 2
    }
  }),
  -- walkable
  [1] = setupTileTypes({
    {
      type = 'floor-1',
      chance = 30 -- number out of 100
    },
    {
      type = 'floor-2',
      chance = 20 -- number out of 100
    },
    {
      type = 'floor-3',
      chance = 45 -- number out of 100
    },
    {
      type = 'floor-4',
      chance = 45 -- number out of 100
    },
    {
      type = 'floor-5',
      chance = 25
    },
    {
      type = 'floor-6',
      chance = 1
    },
    {
      type = 'floor-7',
      chance = 1
    },
    {
      type = 'floor-8',
      chance = 1
    },
    {
      type = 'floor-9',
      chance = 1
    }
  })
}

local MainScene = {
  id = 'MAIN_SCENE',
  group = groups.all,

  -- options
  initialGameState = nil,
  autoSave = true
}

local random = math.random
local Position = require 'utils.position'
local function getDroppablePosition(posX, posY, mapGrid, callCount)
  -- FIXME: prevent infinite recursion from freezing the game. This is a temporary fix.
  callCount = (callCount or 0)

  local dropX, dropY = posX + random(0, 16), posY + random(0, 16)
  local gridX, gridY = Position.pixelsToGridUnits(dropX, dropY, config.gridSize)
  local isWalkable = mapGrid[gridX][gridY] == Map.WALKABLE
  if (not isWalkable) and (callCount < 10) then
    return getDroppablePosition(
      posX,
      posY,
      mapGrid,
      (callCount + 1)
    )
  end
  return dropX, dropY
end

-- custom cursor
local cursorSize = 64
local cursor = love.mouse.newCursor('built/images/cursors/crosshair-white.png', cursorSize/2, cursorSize/2)
love.mouse.setCursor(cursor)

local keys = require 'utils.functional'.keys
local aiTypes = require 'components.spawn.ai-types'
local aiTypesList = keys(aiTypes.types)

local function generateAi(parent, player, map)
  local aiCount = 30
  local generated = 0
  local grid = map.grid
  local rows, cols = #grid, #grid[1]
  local minPos, maxPos = 10, 40
  while generated < aiCount do
    local posX, posY = math.random(minPos, maxPos), math.random(minPos, maxPos)
    local isValidPosition = grid[posY][posX] == Map.WALKABLE
    if isValidPosition then
      generated = generated + 1
      SpawnerAi.create({
        -- debug = true,
        grid = grid,
        WALKABLE = Map.WALKABLE,
        target = player,
        x = posX,
        y = posY,
        types = {
          aiTypesList[math.random(1, #aiTypesList)],
          aiTypesList[math.random(1, #aiTypesList)],
          aiTypesList[math.random(1, #aiTypesList)]
        },
      }):setParent(parent)
    end
  end
end

function MainScene.init(self)
  msgBus.send(msgBus.NEW_GAME)

  local rootState = CreateStore()
  local inventoryController = InventoryController(rootState)
  if self.initialGameState then
    for k,v in pairs(self.initialGameState) do
      rootState:set(k, v)
    end
    -- setup defaults
  else
    local defaultWeapon = require'components.item-inventory.items.definitions.pod-module-initiate'
    local canEquip, errorMsg = rootState:equipItem(defaultWeapon.create(), 1, 1)
    if not canEquip then
      error(errorMsg)
    end

    local defaultHealthPotion = require'components.item-inventory.items.definitions.potion-health'
    local canEquip, errorMsg = rootState:equipItem(defaultHealthPotion.create(), 1, 5)
    if not canEquip then
      error(errorMsg)
    end

    local defaultEnergyPotion = require'components.item-inventory.items.definitions.potion-energy'
    local canEquip, errorMsg = rootState:equipItem(defaultEnergyPotion.create(), 2, 5)
    if not canEquip then
      error(errorMsg)
    end
  end

  self.rootStore = rootState
  local parent = self
  local map = Map.createAdjacentRooms(6, 20)
  local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)
  self.mapGrid = map.grid

  msgBus.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgBus.NEW_GAME == msgType then
      self:delete(true)
    end

    if msgBus.EQUIPMENT_CHANGE == msgType then
      local equipmentChangeHandler = require'components.item-inventory.equipment-change-handler'
      equipmentChangeHandler(rootState)
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
      local dropX, dropY = getDroppablePosition(x, y, map.grid)
      LootGenerator.create({
        x = dropX,
        y = dropY,
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

    if msgBus.PLAYER_STATS_ADD_MODIFIERS == msgType then
      local curState = rootState:get()
      local curMods = curState.statModifiers
      local nextModifiers = msgValue
      for k,v in pairs(curMods) do
        nextModifiers[k] = v + (nextModifiers[k] or 0)
      end
      rootState:set(
        'statModifiers',
        nextModifiers
      )
    end
  end)

  local player = Player.create({
    mapGrid = map.grid,
    rootStore = rootState
  }):setParent(parent)

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

  -- trigger equipment change for items that were previously equipped from loading the state
  msgBus.send(msgBus.EQUIPMENT_CHANGE)

  Hud.create({
    player = player,
    rootStore = rootState
  }):setParent(parent)

  generateAi(parent, player, map)

  if self.autoSave then
    self.autoSaveTimer = tick.recur(function()
      fileSystem.saveFile(
        rootState:getId(),
        rootState:get()
      )
    end, 0.2)
  end
end

function MainScene.final(self)
  if self.autoSave then
    self.autoSaveTimer:stop()
  end
  msgBus.clearAll()
end

return Component.createFactory(MainScene)