local CreateStore = require 'components.state.state'
local UiState = require 'components.state.ui-state'
local msgBus = require 'components.msg-bus'
local Lru = require 'utils.lru'
local Component = require 'modules.component'
local groups = require 'components.groups'

local function newSnapshotStorage()
  return Lru.new(100)
end

local function makeGlobalState(initialGameState)
  return {
    sceneTitle = '',
    activeLevel = {},
    gameClock = 0,
    backgroundColor = {0.2,0.2,0.2},
    gameState = CreateStore(initialGameState),
    uiState = UiState(),
    stateSnapshot = {
      serializedStateByMapId = newSnapshotStorage(),
      serializeAll = function(self, mapId)
        local statesByClass = {}
        local collisionGroups = require 'modules.collision-groups'
        local f = require 'utils.functional'
        local classesToMatch = collisionGroups.create(
          collisionGroups.floorItem,
          collisionGroups.mainMap,
          collisionGroups.environment
        )
        local components = f.reduce({
          groups.all.getAll(),
          groups.firstLayer.getAll(),
          Component.groups.disabled.getAll()
        }, function(components, groupComponents)
          for _,c in pairs(groupComponents) do
            if collisionGroups.matches(c.class or '', classesToMatch) then
              components[c:getId()] = c
            end
          end
          return components
        end, {})

        for _,entity in pairs(Component.groups.mapStateSerializers.getAll()) do
          assert(entity.class ~= nil, 'class is required')
          assert(type(entity.serialize) == 'function', 'serialize function is required')
          components[entity:getId()] = entity
        end

        -- serialize states
        for _,c in pairs(components) do
          local list = statesByClass[c.class]
          if (not list) then
            list = {}
            statesByClass[c.class] = list
          end
          table.insert(list, {
            blueprint = Component.getBlueprint(c),
            state = c:serialize()
          })
        end

        self.serializedStateByMapId:set(mapId, setmetatable(statesByClass, {
          __index = function()
            return {}
          end
        }))
      end,
      consumeSnapshot = function(self, mapId)
        return self.serializedStateByMapId:get(mapId)
      end,
      clearAll = function(self)
        self.serializedStateByMapId = newStateStorage()
      end
    },
    location = {},
    playerPortal = {
      position = nil,
      mapId = nil
    }
  }
end

local globalState = makeGlobalState()

msgBus.on(msgBus.NEW_GAME, function(msg)
  assert(type(msg) == 'table')
  assert(msg.scene ~= nil)

  globalState = makeGlobalState(msg.nextGameState or {})

  msgBus.send(
    msgBus.SCENE_STACK_REPLACE,
    {
      scene = msg.scene
    }
  )
end, 1)

return setmetatable({
  __allowMutation = false
}, {
  __newindex = function(self, k, v)
    if (not self.__allowMutation) then
      error('[NO MUTATION] Could not directly modify the property `'..k..'` of global state.')
    end
    globalState[k] = v
  end,
  __index = function(_, k)
    return globalState[k]
  end
})