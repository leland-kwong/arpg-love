local Component = require 'modules.component'
local groups = require 'components.groups'
local Map = require 'modules.map-generator.index'
local Player = require 'components.player'
local MainMap = require 'components.map.main-map'
local config = require 'config.config'
local camera = require 'components.camera'
local cloneGrid = require 'utils.clone-grid'
local msgBus = require 'components.msg-bus'

local MainScene = {
  id = 'MAIN_SCENE',
  group = groups.firstLayer,
  zoneTitle = 'Aureus',

  -- a map id to restore the state from
  mapId = nil,

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
  msgBus.send(msgBus.NEW_MAP)
  Component.get('lightWorld'):setAmbientColor({0.5,0.5,0.5,1})

  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0,0,0,1})

  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  self.rootStore = rootState
  local parent = self

  local serializedState = msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:consumeSnapshot(self.mapId)
  local Dungeon = require 'modules.dungeon'
  local mapGrid = serializedState and (serializedState.mainMap and serializedState.mainMap[1].state) or Dungeon:getData(self.mapId).grid
  self.mapGrid = mapGrid

  self.listeners = {
    msgBus.on(msgBus.SCENE_STACK_PUSH, function(v)
      msgBus.send(msgBus.GLOBAL_STATE_GET).stateSnapshot:serializeAll(self.mapId)
    end, 1),

    msgBus.on(msgBus.ENEMY_DESTROYED, function(msgValue)
      msgBus.send(msgBus.EXPERIENCE_GAIN, math.floor(msgValue.experience))
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
    mapId = self.mapId
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
      local defaultStartPosition = {x = 4 * config.gridSize, y = 10 * config.gridSize}
      playerStartPos = defaultStartPosition
    end
  end

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