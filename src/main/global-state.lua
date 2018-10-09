local sceneManager = require 'scene.manager'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'

local globalState = {
  activeScene = nil,
  backgroundColor = {0.2,0.2,0.2},
  sceneStack = sceneManager,
  gameState = {},
  stateSnapshot = {
    serializedState = nil,
    serializeAll = function(self)
      local statesByClass = {}
      self.serializedState = statesByClass
      local collisionGroups = require 'modules.collision-groups'
      local f = require 'utils.functional'
      local classesToMatch = collisionGroups.create(
        collisionGroups.ai,
        collisionGroups.floorItem,
        collisionGroups.mainMap,
        'portal'
      )
      local components = f.reduce({
        groups.all.getAll(),
        groups.firstLayer.getAll()
      }, function(components, groupComponents)
        for _,c in pairs(groupComponents) do
          if collisionGroups.matches(c.class or '', classesToMatch) then
            table.insert(components, c)
          end
        end
        return components
      end, {})

      -- serialize states
      for _,c in pairs(components) do
        local list = statesByClass[c.class]
        if (not list) then
          list = {}
          statesByClass[c.class] = list
        end
        table.insert(list, {
          blueprint = getmetatable(c),
          state = c:serialize()
        })
      end
    end,
    consumeSnapshot = function(self)
      local serialized = self.serializedState
      self.serializedState = nil
      return serialized
    end
  }
}

msgBus.on(msgBus.NEW_GAME, function()
  globalState.stateSnapshot:consumeSnapshot()
end)

return globalState