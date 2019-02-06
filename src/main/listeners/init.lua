local globalState = require 'main.global-state'
local gsa = require 'main.global-state-actions'
local msgBus = require 'components.msg-bus'
local sceneManager = require 'scene.manager'
local MusicManager = require 'main.listeners.music-manager'
require 'main.listeners.cursors'(msgBus)

local state = {
  activeScene = nil,
  sceneStack = sceneManager
}

local SCENE_STACK_MESSAGE_LAST_PRIORITY = 10

local function sceneStackPush(msgValue)
  local nextScene = msgValue
  if state.activeScene then
    state.activeScene:delete(true)
  end
  local sceneRef = nextScene.scene.create(nextScene.props)
  state.activeScene = sceneRef
  gsa('setSceneTitle', state.activeScene.zoneTitle)
  state.sceneStack:push(nextScene)
  msgBus.send(msgBus.MUSIC_PLAY, sceneRef)
  msgBus.send(msgBus.SCENE_CHANGE, sceneRef)
  return sceneRef
end

msgBus.on(msgBus.SCENE_STACK_PUSH, sceneStackPush, SCENE_STACK_MESSAGE_LAST_PRIORITY)

msgBus.on(msgBus.SCENE_STACK_POP, function()
  if state.activeScene then
    state.activeScene:delete(true)
  end
  local poppedScene = state.sceneStack:pop()
  local sceneRef = poppedScene.scene.create(poppedScene.props)
  state.activeScene = sceneRef
  gsa('setSceneTitle', state.activeScene.zoneTitle)
  msgBus.send(msgBus.MUSIC_PLAY, sceneRef)
  msgBus.send(msgBus.SCENE_CHANGE, sceneRef)
  return sceneRef
end, SCENE_STACK_MESSAGE_LAST_PRIORITY)

msgBus.on(msgBus.SCENE_STACK_REPLACE, function(nextScene)
  state.sceneStack:clear()
  --[[
    call scene push function directly instead of triggering the `SCENE_STACK_PUSH` event since there are modules that
    trigger specifically on `SCENE_STACK_PUSH`
  ]]
  return sceneStackPush(nextScene)
end, SCENE_STACK_MESSAGE_LAST_PRIORITY)