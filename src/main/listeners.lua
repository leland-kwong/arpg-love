local globalState = require 'main.global-state'
local msgBus = require 'components.msg-bus'

local SCENE_STACK_MESSAGE_LAST_PRIORITY = 10

msgBus.on(msgBus.SCENE_STACK_PUSH, function(msgValue)
  local nextScene = msgValue
  if globalState.activeScene then
    globalState.activeScene:delete(true)
  end
  local sceneRef = nextScene.scene.create(nextScene.props)
  globalState.activeScene = sceneRef
  globalState.sceneStack:push(nextScene)
  return sceneRef
end, SCENE_STACK_MESSAGE_LAST_PRIORITY)

msgBus.on(msgBus.SCENE_STACK_POP, function()
  if globalState.activeScene then
    globalState.activeScene:delete(true)
  end
  local poppedScene = globalState.sceneStack:pop()
  local sceneRef = poppedScene.scene.create(poppedScene.props)
  globalState.activeScene = sceneRef
  return sceneRef
end, SCENE_STACK_MESSAGE_LAST_PRIORITY)

msgBus.on(msgBus.SCENE_STACK_REPLACE, function(nextScene)
  globalState.sceneStack:clear()
  return msgBus.send(msgBus.SCENE_STACK_PUSH, nextScene)
end, SCENE_STACK_MESSAGE_LAST_PRIORITY)

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

msgBus.on(msgBus.NEW_GAME, function(msg)
  assert(type(msg) == 'table')
  assert(msg.scene ~= nil)
  assert(type(msg.props.characterName) == 'string', 'character name should be a string')

  local CreateStore = require 'components.state.state'
  msgBus.send(msgBus.GAME_STATE_SET, CreateStore(msg.props))
  msgBus.send(
    msgBus.SCENE_STACK_REPLACE,
    {
      scene = msg.scene
    }
  )
end)