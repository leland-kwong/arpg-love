local globalState = require 'main.global-state'
local Lru = require 'utils.lru'
local Component = require 'modules.component'
local groups = require 'components.groups'

local function newSnapshotStorage()
  return Lru.new(100)
end

local actions = {
  setBackgroundColor = function(color)
    globalState.backgroundColor = color
  end,
  updateGameClock = function(dt)
    globalState.gameClock = globalState.gameClock + dt
  end,
  setNewGameState = function(nextGameState)
    local CreateStore = require 'components.state.state'
    globalState.gameState = CreateStore(nextGameState)

    local UiState = require 'components.state.ui-state'
    globalState.uiState = UiState()

    globalState.stateSnapshot = {
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
    }
  end,
  setActiveLevel = function(level)
    globalState.activeLevel = level
  end,
  setSceneTitle = function(title)
    globalState.sceneTitle = title or ''
  end
}

return function(action, payload)
  globalState.__allowMutation = true
  actions[action](payload)
  globalState.__allowMutation = false
end