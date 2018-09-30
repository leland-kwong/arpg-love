local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local MainMap = require 'components.map.main-map'
local SpawnerAi = require 'components.spawn.spawn-ai'
local config = require 'config.config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local msgBus = require 'components.msg-bus'

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
  isNewGame = false
}

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
    local posX, posY = math.random(10, rows), math.random(10, cols)
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

local function initializeMap()
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

local function setupLightWorld()
  local LightWorld = require('shadows.LightWorld')
  local newLightWorld = LightWorld:new()
  local ambientColor = 0.7
  newLightWorld:SetColor(ambientColor*255,ambientColor*255,ambientColor*255)
  return Component.create({
    id = 'DUNGEON_LIGHT_WORLD',
    group = groups.all,
    init = function(self)
      self.lightWorld = newLightWorld
    end,
    update = function(self)
      local scale = require 'config.config'.scale
      local camera = require 'components.camera'
      local x, y = camera:getPosition()
      newLightWorld:SetPosition(x * scale, y * scale)
      newLightWorld:Update()
    end,
    draw = function()
      love.graphics.push()
      newLightWorld:Draw()
      love.graphics.pop()
    end,
    drawOrder = function()
      return math.pow(10, 10)
    end
  })
end

function MainScene.init(self)
  local serializedState = msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:consumeSnapshot()

  self.lightWorld = setupLightWorld():setParent(self)
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {1,1,1,1})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  self.rootStore = rootState
  local parent = self

  local mapGrid = serializedState and serializedState.mainMap[1].state or initializeMap()
  local gridTileDefinitions = cloneGrid(mapGrid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    return tileGroup[math.random(1, #tileGroup)]
  end)
  self.mapGrid = mapGrid

  self.listeners = {
    msgBus.on(msgBus.SCENE_STACK_PUSH, function(v)
      msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:serializeAll()
    end, 1),
    -- setup default properties in case they don't exist
    msgBus.on(msgBus.CHARACTER_HIT, function(v)
      v.damage = v.damage or 0
      return v
    end, 1),

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

    msgBus.on(msgBus.ENTITY_DESTROYED, function(msgValue)
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
      local HomeBase = require('scene.home-base')
      local Vec2 = require 'modules.brinevector'
      msgBus.send(
        msgBus.SCENE_STACK_PUSH, {
          scene = HomeBase
        }
      )
    end)
  }

  local playerStartPos = serializedState and
    serializedState.portal[1].state.position or
    {x = 6 * config.gridSize, y = 5 * config.gridSize}
  local player = Player.create({
    x = playerStartPos.x,
    y = playerStartPos.y,
    mapGrid = mapGrid,
  }):setParent(parent)

  local Lights = require 'components.lights'
  Lights.create({
    x = player.x,
    y = player.y,
    radius = 400,
    lightWorld = 'DUNGEON_LIGHT_WORLD'
  }):setParent(player)

  MainMap.create({
    camera = camera,
    grid = mapGrid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE
  }):setParent(parent)

  if serializedState then
    for i=1, #(serializedState.floorItem or {}) do
      local item = serializedState.floorItem[i]
      item.blueprint.create(item.state):setParent(self)
    end

    -- rebuild ai from previous state
    for i=1, #(serializedState.ai or {}) do
      local item = serializedState.ai[i]
      item.blueprint.create(item.state):setParent(self)
    end
  else
    generateAi(parent, player, mapGrid)
  end
end

function MainScene.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(MainScene)