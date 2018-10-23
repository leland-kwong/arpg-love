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

local backgroundTypes = {
  starField = function()
    local StarField = require 'components.star-field'
    local Color = require 'modules.color'
    local starField = StarField.create({
      particleBaseColor = {Color.rgba255(244, 66, 217)},
      updateRate = 30,
      direction = 0,
      emissionRate = 4000,
      speed = {0}
    }):setParent(Component.get('MAIN_SCENE'))
    msgBus.on(msgBus.UPDATE, function()
      if starField:isDeleted() then
        return msgBus.CLEANUP
      end
      local camera = require 'components.camera'
      local x, y = camera:getPosition()
      starField:setPosition(
        x * 0.5,
        y * 0.5
      )
    end)
    return starField
  end
}

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

  -- options
  isNewGame = false
}

-- custom cursor
local cursorSize = 64
local cursor = love.mouse.newCursor('built/images/cursors/crosshair-white.png', cursorSize/2, cursorSize/2)
love.mouse.setCursor(cursor)

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
      mapBlockGenerator
    }
    while #mapDefinitions > 0 do
      local index = math.random(1, #mapDefinitions)
      local block = table.remove(mapDefinitions, index)()
      table.insert(blocks, block)
    end
    local bossRoomIndex = math.random(#blocks - 1, #blocks)
    table.insert(blocks, bossRoomIndex, 'room-boss-1')
    return blocks
  end

  local mapGrid = Dungeon.new(generateMapBlockDefinitions(), { columns = 2 })
  return mapGrid
end

local function setupLightWorld()
  local LightWorld = require('components.light-world')
  local width, height = love.graphics.getDimensions()
  local newLightWorld = LightWorld:new(width, height)
  local ambientColor = {0.6,0.6,0.6,1}
  newLightWorld:setAmbientColor(ambientColor)

  Component.create({
    group = groups.all,
    update = function()
      local cameraTranslateX, cameraTranslateY = camera:getPosition()
      local cWidth, cHeight = camera:getSize()
      newLightWorld:setPosition(-cameraTranslateX + cWidth/2, -cameraTranslateY + cHeight/2)
      local playerRef = Component.get('PLAYER')
      local tx, ty = playerRef:getPosition()

      -- draw light around player
      newLightWorld:addLight(
        tx, ty,
        80,
        {1,1,1}
      )
    end,
    draw = function()
      love.graphics.push()
      love.graphics.origin()
      love.graphics.scale(2)
      local jprof = require 'modules.profile'
      newLightWorld:draw()
      love.graphics.pop()
    end,
    drawOrder = function()
      return 100 * 100
    end
  }):setParent(Component.get('MAIN_SCENE'))

  return newLightWorld
end

function MainScene.init(self)
  -- self.backgroundComponent = backgroundTypes.starField()
  local serializedState = msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:consumeSnapshot()

  self.lightWorld = setupLightWorld()
  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0,0,0,1})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  self.rootStore = rootState
  local parent = self

  local mapGrid = serializedState and serializedState.mainMap[1].state or initializeMap()
  local gridTileDefinitions = cloneGrid(mapGrid, function(v, x, y)
    local tileGroup = gridTileTypes[v]
    if tileGroup then
      return tileGroup[math.random(1, #tileGroup)]
    end
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

  local playerStartPos =
    serializedState and
    serializedState.portal[1] and
    serializedState.portal[1].state.position or

    {x = 6 * config.gridSize, y = 5 * config.gridSize}
  local player = Player.create({
    x = playerStartPos.x,
    y = playerStartPos.y,
    mapGrid = mapGrid,
  }):setParent(parent)

  MainMap.create({
    camera = camera,
    grid = mapGrid,
    tileRenderDefinition = gridTileDefinitions,
    walkable = Map.WALKABLE,
    drawOrder = function()
      return 1
      -- return parent.backgroundComponent:drawOrder() + 1
    end
  }):setParent(parent)

  if serializedState then
    -- rebuild loot from previous state
    for i=1, #(serializedState.floorItem or {}) do
      local item = serializedState.floorItem[i]
      item.blueprint.create(item.state):setParent(self)
    end

    -- rebuild ai from previous state
    for i=1, #(serializedState.ai or {}) do
      local item = serializedState.ai[i]
      item.blueprint.create(item.state):setParent(self)
    end

    -- rebuild treasure environment objects from previous state
    for i=1, #(serializedState.environment) do
      local item = serializedState.environment[i]
      item.blueprint.create(item.state):setParent(self)
    end
  else
    Component.addToGroup(self:getId(), 'dungeonTest', self)
  end
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

  for _,entity in pairs(activeEntities) do
    entity.isInViewOfPlayer = false
  end
  activeEntities = {}

  for i=1, len do
    local entity = items[i].parent
    local entityId = entity:getId()
    entity.isInViewOfPlayer = true
    activeEntities[entityId] = entity
  end
end

function MainScene.update(self)
  local jprof = require 'modules.profile'
  jprof.push('toggleEntityVisibility')
  toggleEntityVisibility(self)
  jprof.pop('toggleEntityVisibility')
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