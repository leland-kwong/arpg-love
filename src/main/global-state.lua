local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'

Component.newGroup({
  name = 'mapStateSerializers'
})

local function makeGlobalState()
  return {
    sceneTitle = '',
    activeLevel = '',
    gameClock = 0,
    backgroundColor = {0.2,0.2,0.2},
    gameState = {},
    uiState = {},
    stateSnapshot = {}
  }
end

local globalState = makeGlobalState()

msgBus.on(msgBus.NEW_GAME, function(msg)
  assert(type(msg) == 'table')
  assert(msg.scene ~= nil)

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