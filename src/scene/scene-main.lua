local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local MainMap = require 'components.map.main-map'
local config = require 'config.config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local msgBus = require 'components.msg-bus'
local globalState = require 'main.global-state'
local mapLayoutGenerator = require 'modules.dungeon.map-layout-generator'
local gsa = require 'main.global-state-actions'

Component.create({
  id = 'MainSceneInitializer',
  group = 'firstLayer',
  init = function(self)
    self.listeners = {
      -- serialize the state when the scene is changed
      msgBus.on('SCENE_STACK_REPLACE', function()
        local mainSceneRef = Component.get('MAIN_SCENE')
        if mainSceneRef then
          local mapId = mapLayoutGenerator.get(mainSceneRef.location)
          globalState.stateSnapshot:serializeAll(mapId)
          msgBus.send('MAP_UNLOADED')
        end
      end, 0)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})

local MainScene = {
  id = 'MAIN_SCENE',
  group = groups.firstLayer,
  zoneTitle = 'Aureus',

  -- options
  isNewGame = false
}

local function restoreComponentsFromState(self, serializedState)
  local classesToRestore = {
    'floorItem',
    'enemyAi',
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
  Component.get('lightWorld'):setAmbientColor({0.5,0.5,0.5,1})

  gsa.setBackgroundColor({0,0,0,1})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  self.rootStore = rootState
  local parent = self

  local mapId = mapLayoutGenerator.get(self.location)
  local serializedState = globalState.stateSnapshot:consumeSnapshot(mapId)
  local Dungeon = require 'modules.dungeon'
  local dungeonRef = Dungeon:getData(mapId)
  gsa.setActiveLevel(dungeonRef.options.layoutType)
  local startPoint = dungeonRef.startPoint
  local mapGrid = dungeonRef.grid
  self.mapId = mapId
  self.mapGrid = mapGrid

  self.listeners = {
    msgBus.on(msgBus.ENEMY_DESTROYED, function(msgValue)
      msgBus.send(msgBus.EXPERIENCE_GAIN, math.floor(msgValue.experience))
    end),

    msgBus.on(msgBus.PORTAL_ENTER, function(location)
      if location.type == 'universe' then
        msgBus.send('MAP_TOGGLE')
        return
      end

      local Sound = require 'components.sound'
      Sound.playEffect('portal-enter.wav')

      if location.from == 'player' then
        local HomeBase = require('scene.home-base')
        msgBus.send(
          msgBus.SCENE_STACK_REPLACE, {
            scene = HomeBase,
            props = {
              location = {
                from = 'player',
                layoutType = self.location.layoutType
              }
            }
          }
        )
        return
      end

      if location.from == 'universe' then
        local HomeBase = require('scene.home-base')
        msgBus.send(
          msgBus.SCENE_STACK_REPLACE, {
            scene = HomeBase,
            props = {
              location = {
                from = 'universe',
                layoutType = self.location.layoutType
              }
            }
          }
        )
        return
      end

      -- travel to a specific location in the universe
      msgBus.send(msgBus.SCENE_STACK_REPLACE, {
        scene = require 'scene.scene-main',
        props = {
          location = location
        }
      })
    end)
  }

  MainMap.create({
    camera = camera,
    mapId = mapId
  }):setParent(parent)

  if serializedState then
    restoreComponentsFromState(self, serializedState)
  else
    Component.addToGroup(self:getId(), 'dungeonTest', self)
  end

  local playerStartPos =
    (self.location.from == 'player') and
    Component.get('PlayerPortal')

  if (not playerStartPos) then
    if self.exitId then
      local x, y = Component.get(self.exitId):getPosition()
      local entranceXOffset = 1 * config.gridSize
      local entranceYOffset = 3 * config.gridSize
      playerStartPos = {x = x + entranceXOffset, y = y + entranceYOffset}
    else
      playerStartPos = startPoint
    end
  end

  local Portal = require 'components.portal'
  Portal.create({
    id = 'LayoutStartPosition',
    x = startPoint.x,
    y = startPoint.y - 10,
    style = 2,
    color = {1,1,1},
    location = {
      tooltipText = 'Universe Portal',
      type = 'universe'
    }
  })

  local player = Player.create({
    x = playerStartPos.x,
    y = playerStartPos.y,
    mapGrid = mapGrid,
  }):setParent(parent)
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