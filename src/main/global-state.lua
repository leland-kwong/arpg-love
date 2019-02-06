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

return setmetatable({}, {
  __newindex = function(_, k, v)
    globalState[k] = v
  end,
  __index = function(_, k)
    return globalState[k]
  end
})