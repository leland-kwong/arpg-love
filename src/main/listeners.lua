local globalState = require 'main.global-state'
local msgBus = require 'components.msg-bus'

msgBus.on(msgBus.SCENE_STACK_PUSH, function(msgValue)
  local nextScene = msgValue
  if globalState.activeScene then
    globalState.activeScene:delete(true)
  end
  local sceneRef = nextScene.scene.create(nextScene.props)
  globalState.activeScene = sceneRef
  globalState.sceneStack:push(nextScene)
end)

msgBus.on(msgBus.SCENE_STACK_POP, function()
  if globalState.activeScene then
    globalState.activeScene:delete(true)
  end
  local poppedScene = globalState.sceneStack:pop()
  globalState.activeScene = poppedScene.scene.create(poppedScene.props)
end)

msgBus.on(msgBus.SCENE_STACK_REPLACE, function(nextScene)
  globalState.sceneStack:clear()
  msgBus.send(msgBus.SCENE_STACK_PUSH, nextScene)
end)

msgBus.on(msgBus.SET_CONFIG, function(msgValue)
  local configChanges = msgValue
  local oUtils = require 'utils.object-utils'
  oUtils.assign(config, configChanges)
end)

msgBus.on(msgBus.GAME_STATE_SET, function(state)
  globalState.gameState = state
end)

msgBus.on(msgBus.GAME_STATE_GET, function()
  return globalState.gameState
end)

msgBus.on(msgBus.SET_BACKGROUND_COLOR, function(color)
  globalState.backgroundColor = color
end)

msgBus.on(msgBus.GLOBAL_STATE_GET, function()
  return globalState
end)