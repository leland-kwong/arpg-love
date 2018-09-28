local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local MainMap = require 'components.map.main-map'
local Inventory = require 'components.item-inventory.inventory'
local SpawnerAi = require 'components.spawn.spawn-ai'
local InventoryController = require 'components.item-inventory.controller'
local config = require 'config.config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local Hud = require 'components.hud.hud'
local fileSystem = require 'modules.file-system'
local msgBus = require 'components.msg-bus'
local HealSource = require 'components.heal-source'
local tick = require 'utils.tick'
require 'components.item-inventory.items.equipment-base-subscriber'

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
  group = groups.firstLayer,

  -- options
  isNewGame = false,
  autoSave = true
}

local random = math.random
local Position = require 'utils.position'
local function getDroppablePosition(posX, posY, mapGrid, callCount)
  -- FIXME: prevent infinite recursion from freezing the game. This is a temporary fix.
  callCount = (callCount or 0)

  local dropX, dropY = posX + random(0, 16), posY + random(0, 16)
  local gridX, gridY = Position.pixelsToGridUnits(dropX, dropY, config.gridSize)
  local isWalkable = mapGrid[gridY][gridX] == Map.WALKABLE
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
local aiTypes = require 'components.ai.types'
local aiTypesList = keys(aiTypes.types)

local function generateAi(parent, player, mapGrid)
  local aiCount = 20
  local generated = 0
  local grid = mapGrid
  local rows, cols = #grid, #grid[1]
  while generated < aiCount do
    local posX, posY = math.random(10, cols - 1), math.random(10, rows - 1)
    local isValidPosition = grid[posY][posX] == Map.WALKABLE
    if isValidPosition then
      generated = generated + 1
      SpawnerAi.create({
        -- debug = true,
        grid = grid,
        WALKABLE = Map.WALKABLE,
        target = function()
          return Component.get('PLAYER')
        end,
        x = posX,
        y = posY,
        types = {
          -- aiTypes.types.SLIME
          aiTypesList[math.random(1, #aiTypesList)],
          aiTypesList[math.random(1, #aiTypesList)],
          aiTypesList[math.random(1, #aiTypesList)]
        },
      }):setParent(parent)
    end
  end
end

function initializeMap()
  local Dungeon = require 'modules.dungeon'
  local Chance = require 'utils.chance'
  local mapBlockGenerator = Chance({
    {
      chance = 1,
      value = 'room-1'
    },
    {
      chance = 1,
      value = 'room-2'
    },
    {
      chance = 1,
      value = 'room-3'
    },
    {
      chance = 1,
      value = 'room-4'
    },
    {
      chance = 1,
      value = 'room-5'
    }
  })

  local function generateMapBlockDefinitions()
    local blocks = {}
    local mapDefinitions = {
      function()
        return 'room-3'
      end,
      mapBlockGenerator,
      mapBlockGenerator,
      mapBlockGenerator,
      mapBlockGenerator,
      mapBlockGenerator
    }
    while #mapDefinitions > 0 do
      local index = math.random(1, #mapDefinitions)
      local block = table.remove(mapDefinitions, index)()
      table.insert(blocks, block)
    end
    return blocks
  end

  local mapGrid = Dungeon.new(generateMapBlockDefinitions())
  return mapGrid
end

function MainScene.init(self)
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0,0,0,0})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  local inventoryController = InventoryController(rootState)

  -- add default weapons
  if rootState:get().isNewGame then
    local defaultWeapon = require'components.item-inventory.items.definitions.pod-module-hammer'
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

    local defaultBoots = require'components.item-inventory.items.definitions.mock-shoes'
    local canEquip, errorMsg = rootState:equipItem(defaultBoots.create(), 1, 4)
    if not canEquip then
      error(errorMsg)
    end

    local defaultWeapon2 = require'components.item-inventory.items.definitions.lightning-rod'
    local canEquip, errorMsg = rootState:equipItem(defaultWeapon2.create(), 1, 2)
    if not canEquip then
      error(errorMsg)
    end

    local defaultArmor = require('components.item-inventory.items.definitions.mock-armor').create()
    local canEquip, errorMsg = rootState:equipItem(defaultArmor, 2, 3)
    if not canEquip then
      error(errorMsg)
    end

    local defaultWeapon3 = require'components.item-inventory.items.definitions.pod-module-fireball'
    rootState:addItemToInventory(defaultWeapon3.create())
  end

  local stateId = rootState:getId()
  consoleLog(stateId)

  self.rootStore = rootState
  local parent = self
  local mapGrid = initializeMap()
  local gridTileDefinitions = cloneGrid(mapGrid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)
  self.mapGrid = mapGrid

  self.listeners = {
    -- setup default properties in case they don't exist
    msgBus.on(msgBus.CHARACTER_HIT, function(v)
      v.damage = v.damage or 0
      return v
    end, 1),

    msgBus.on(msgBus.PLAYER_STATS_ADD_MODIFIERS, function(msgValue)
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
    end),

    msgBus.on(msgBus.PLAYER_STATS_NEW_MODIFIERS, function(msgValue)
      local newModifiers = msgValue
      rootState:set('statModifiers', newModifiers)
    end),

    msgBus.on(msgBus.GENERATE_LOOT, function(msgValue)
      local LootGenerator = require'components.loot-generator.loot-generator'
      local x, y, item = unpack(msgValue)
      if not item then
        return
      end
      local dropX, dropY = getDroppablePosition(x, y, mapGrid)
      LootGenerator.create({
        x = dropX,
        y = dropY,
        item = item,
        rootStore = rootState
      }):setParent(parent)
    end),

    msgBus.on(msgBus.EQUIPMENT_CHANGE, function()
      local equipmentChangeHandler = require'components.item-inventory.equipment-change-handler'
      equipmentChangeHandler(rootState)
    end),

    msgBus.on(msgBus.KEY_PRESSED, function(v)
      local key = v.key
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

      if config.keyboard.PORTAL_OPEN == key then
        msgBus.send(msgBus.PORTAL_OPEN)
      end
    end),

    msgBus.on(msgBus.PLAYER_HEAL_SOURCE_ADD, function(v)
      HealSource.add(self, v, rootState)
    end),

    msgBus.on(msgBus.PLAYER_HEAL_SOURCE_REMOVE, function(v)
      HealSource.remove(self, v.source)
    end),

    msgBus.on(msgBus.ENEMY_DESTROYED, function(msgValue)
      local lootAlgorithm = require 'components.loot-generator.algorithm-1'
      local randomItem = lootAlgorithm()
      if randomItem then
        msgBus.send(msgBus.GENERATE_LOOT, {msgValue.x, msgValue.y, randomItem})
      end
      msgBus.send(msgBus.EXPERIENCE_GAIN, math.floor(msgValue.experience))
    end),

    msgBus.on(msgBus.PORTAL_OPEN, function()
      local Portal = require 'components.portal'
      self.portal = self.portal or Portal.create()
      local playerRef = Component.get('PLAYER')
      local x, y = playerRef:getPosition()
      self.portal
        :set('locationName', 'home')
        :setPosition(x, y)
        :setParent(self)
    end),

    msgBus.on(msgBus.PORTAL_ENTER, function()
      local msgBusMainMenu = require 'components.msg-bus-main-menu'
      local HomeBase = require('scene.home-base')
      msgBusMainMenu.send(
        msgBusMainMenu.SCENE_STACK_PUSH, {
          scene = HomeBase
        }
      )
    end)
  }

  local player = Player.create({
    x = 3 * config.gridSize,
    y = 3 * config.gridSize,
    mapGrid = mapGrid,
    rootStore = rootState
  }):setParent(parent)

  MainMap.create({
    camera = camera,
    grid = mapGrid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE
  }):setParent(parent)

  -- trigger equipment change for items that were previously equipped from loading the state
  msgBus.send(msgBus.EQUIPMENT_CHANGE)

  Hud.create({
    player = player,
    rootStore = rootState
  }):setParent(parent)

  generateAi(parent, player, mapGrid)

  if self.autoSave then
    local lastSavedState = nil
    local function saveState()
      rootState:set('isNewGame', false)
      local state = rootState:get()
      local hasChanged = state ~= lastSavedState
      if hasChanged then
        fileSystem.saveFile(
          rootState:getId(),
          rootState:get()
        )
        lastSavedState = state
      end
    end
    self.autoSaveTimer = tick.recur(saveState, 0.5)
  end
end

function MainScene.final(self)
  msgBus.off(self.listeners)
  if self.autoSave then
    self.autoSaveTimer:stop()
  end
end

return Component.createFactory(MainScene)