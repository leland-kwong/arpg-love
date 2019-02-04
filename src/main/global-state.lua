local Component = require 'modules.component'
local sceneManager = require 'scene.manager'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local CreateStore = require 'components.state.state'
local UiState = require 'components.state.ui-state'
local Lru = require 'utils.lru'

local function newStateStorage()
  return Lru.new(100)
end

Component.newGroup({
  name = 'mapStateSerializers'
})

local function makeGlobalState()
  return {
    activeScene = nil,
    backgroundColor = {0.2,0.2,0.2},
    sceneStack = sceneManager,
    gameState = CreateStore(),
    uiState = UiState(),
    mapLayoutsCache = {
      cache = {},
      get = function(self, locationProps)
        local Dungeon = require 'modules.dungeon'
        local layoutType = locationProps.layoutType
        local mapId = self.cache[layoutType]
        if (not mapId) then
          mapId = Dungeon:new(locationProps)
          self.cache[layoutType] = mapId
        end
        return mapId
      end,
      clear = function(self)
        self.cache = {}
      end
    },
    stateSnapshot = {
      serializedStateByMapId = newStateStorage(),
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
    }
  }
end

local globalState = makeGlobalState()

msgBus.on(msgBus.NEW_GAME, function()
  globalState = makeGlobalState()
end, 1)

return setmetatable({}, {
  __index = function(_, k)
    return globalState[k]
  end
})