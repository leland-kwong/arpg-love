local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local MainMap = require 'components.map.main-map'
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
  zoneTitle = 'Aureus',

  -- a map id to restore the state from
  mapId = nil,

  -- options
  isNewGame = false
}

-- custom cursor
local cursorSize = 64
local cursor = love.mouse.newCursor('built/images/cursors/crosshair-white.png', cursorSize/2, cursorSize/2)
love.mouse.setCursor(cursor)

local function restoreComponentsFromState(self, serializedState)
  local classesToRestore = {
    'floorItem',
    'ai',
    'environment'
  }
  local F = require 'utils.functional'
  F.forEach(classesToRestore, function(class)
    for i=1, #(serializedState[class] or {}) do
      local item = serializedState[class][i]
      item.blueprint.create(item.state):setParent(self)
    end
  end)
end

function MainScene.init(self)
  msgBus.send(msgBus.NEW_MAP)
  Component.get('lightWorld').ambientColor = {0.6,0.6,0.6,1}


  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0,0,0,1})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  self.rootStore = rootState
  local parent = self

  local serializedState = msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:consumeSnapshot(self.mapId)
  local Dungeon = require 'modules.dungeon'
  local mapGrid = serializedState and (serializedState.mainMap and serializedState.mainMap[1].state) or Dungeon:getData(self.mapId).grid
  local gridTileDefinitions = cloneGrid(mapGrid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    if tileGroup then
      return tileGroup[math.random(1, #tileGroup)]
    end
  end)
  self.mapGrid = mapGrid

  self.listeners = {
    msgBus.on(msgBus.SCENE_STACK_PUSH, function(v)
      msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:serializeAll(self.mapId)
    end, 1),
    -- setup default properties in case they don't exist
    msgBus.on(msgBus.CHARACTER_HIT, function(v)
      v.damage = v.damage or 0
      return v
    end, 1),

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
      msgBus.send(
        msgBus.SCENE_STACK_PUSH, {
          scene = HomeBase
        }
      )
    end)
  }

  MainMap.create({
    camera = camera,
    grid = mapGrid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE,
    drawOrder = function()
      return 1
    end
  }):setParent(parent)

  if serializedState then
    restoreComponentsFromState(self, serializedState)
  else
    Component.addToGroup(self:getId(), 'dungeonTest', self)
  end

  local playerStartPos =
    serializedState and
    serializedState.portal[1] and
    serializedState.portal[1].state.position
  if (not playerStartPos) then
    if self.exitId then
      local x, y = Component.get(self.exitId):getPosition()
      local entranceXOffset = 1 * config.gridSize
      local entranceYOffset = 3 * config.gridSize
      playerStartPos = {x = x + entranceXOffset, y = y + entranceYOffset}
    else
      local defaultStartPosition = {x = 4 * config.gridSize, y = 5 * config.gridSize}
      playerStartPos = defaultStartPosition
    end
  end

  local player = Player.create({
    x = playerStartPos.x,
    y = playerStartPos.y,
    mapGrid = mapGrid,
  }):setParent(parent)
end

local collisionGroups = require 'modules.collision-groups'
local visibilityGroup = collisionGroups.create(
  collisionGroups.ai,
  collisionGroups.environment
)
local activeEntities = {}

local matchers = {
  [collisionGroups.ai] = true,
  [collisionGroups.environment] = true
}

local function visibleItemFilter(item)
  return collisionGroups.matches(item.group, visibilityGroup)
end

local floor = math.floor
local function toggleEntityVisibility(self)
  local collisionWorlds = require 'components.collision-worlds'
  local camera = require 'components.camera'
  local threshold = config.gridSize * 2
  local west, _, north = camera:getBounds()
  local width, height = camera:getSize()
  local items, len = collisionWorlds.map:queryRect(
    west - threshold,
    north - threshold, width + (threshold * 2),
    height + (threshold * 2),
    visibleItemFilter
  )

  -- reset active entities
  for _,entity in pairs(activeEntities) do
    entity.isInViewOfPlayer = false
  end
  activeEntities = {}

  -- set new list of active entities
  for i=1, len do
    local entity = items[i].parent
    local entityId = entity:getId()
    entity.isInViewOfPlayer = true
    activeEntities[entityId] = entity
  end
end

function MainScene.update(self)
  toggleEntityVisibility(self)
end

local perf = require'utils.perf'
MainScene.update = perf({
  enabled = false,
  done = function(time, totalTime, callCount)
    local avgTime = totalTime / callCount
    if (callCount % 100) == 0 then
      consoleLog('main scene update -', string.format('%0.3f', avgTime))
    end
  end
})(MainScene.update)

function MainScene.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(MainScene)