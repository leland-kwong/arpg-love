-- can't use lua strict right now because 'jumper' library uses globals which throws errors
-- require 'lua_modules.strict'

require 'components.run'

-- NOTE: this is necessary for crisp pixel rendering
love.graphics.setDefaultFilter('nearest', 'nearest')

local Console = require 'modules.console.console'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local groups = require 'components.groups'
local config = require 'config.config'
local camera = require 'components.camera'
local SceneMain = require 'scene.scene-main'
local RootScene = require 'scene.sandbox.main'
local tick = require 'utils.tick'
local sceneManager = require 'scene.manager'

local scale = config.scaleFactor

local globalState = {
  activeScene = nil,
  backgroundColor = {0.2,0.2,0.2},
  sceneStack = sceneManager,
  gameState = nil
}

function love.load()
  msgBus.send(msgBus.GAME_LOADED)
  love.keyboard.setKeyRepeat(true)
  local resolution = config.resolution
  local vw, vh = resolution.w * scale, resolution.h * scale
  love.window.setMode(vw, vh)
  camera
    :setSize(vw, vh)
    :setScale(scale)

  RootScene.create()

  -- console debugging
  local console = Console.create()
  require 'components.profiler.component-groups'(console)

  msgBusMainMenu.on(msgBusMainMenu.SCENE_STACK_PUSH, function(msgValue)
    local nextScene = msgValue
    if globalState.activeScene then
      globalState.activeScene:delete(true)
    end
    local sceneRef = nextScene.scene.create(nextScene.props)
    globalState.activeScene = sceneRef
    globalState.sceneStack:push(nextScene)
  end)

  msgBusMainMenu.on(msgBusMainMenu.SCENE_STACK_POP, function()
    if globalState.activeScene then
      globalState.activeScene:delete(true)
    end
    local poppedScene = globalState.sceneStack:pop()
    globalState.activeScene = poppedScene.scene.create(poppedScene.props)
  end)

  msgBusMainMenu.on(msgBusMainMenu.SCENE_STACK_REPLACE, function(nextScene)
    globalState.sceneStack:clear()
    msgBusMainMenu.send(msgBusMainMenu.SCENE_STACK_PUSH, nextScene)
  end)

  -- FIXME: this is only for debugging
  msgBus.on(msgBus.PORTAL_ENTER, function()
    consoleLog(#globalState.sceneStack)
  end, 100)

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
end

function love.update(dt)
  tick.update(dt)

  camera:update(dt)
  groups.firstLayer.updateAll(dt)
  groups.all.updateAll(dt)
  groups.overlay.updateAll(dt)
  groups.debug.updateAll(dt)
  groups.hud.updateAll(dt)
  groups.gui.updateAll(dt)
  groups.system.updateAll(dt)
end

local inputMsg = require 'utils.pooled-table'(function(t, key, scanCode, isRepeated)
  t.key = key
  t.code = scanCode
  t.isRepeated = isRepeated
  return t
end)

function love.keypressed(key, scanCode, isRepeated)
  msgBus.send(
    msgBus.KEY_PRESSED,
    inputMsg(key, scanCode, isRepeated)
  )

  if config.keyboard.MAIN_MENU == key then
    msgBusMainMenu.send(
      msgBusMainMenu.TOGGLE_MAIN_MENU
    )
  end
end

function love.keyreleased(key, scanCode)
  msgBus.send(
    msgBus.KEY_RELEASED,
    inputMsg(key, scanCode, false)
  )
end

function love.mousepressed( x, y, button, istouch, presses )
  msgBus.send(
    msgBus.MOUSE_PRESSED,
    { x, y, button, istouch, presses }
  )
end

function love.mousereleased( x, y, button, istouch, presses )
  msgBus.send(
    msgBus.MOUSE_RELEASED,
    { x, y, button, isTouch, presses }
  )
end

function love.wheelmoved(x, y)
  msgBus.send(msgBus.MOUSE_WHEEL_MOVED, {x, y})
end

function love.textinput(t)
  msgBus.send(
    msgBus.GUI_TEXT_INPUT,
    t
  )
end

function love.draw()
  camera:attach()
  -- background
  love.graphics.clear(globalState.backgroundColor)
  groups.firstLayer.drawAll()
  groups.all.drawAll()
  groups.overlay.drawAll()
  groups.debug.drawAll()
  camera:detach()

  love.graphics.push()
  love.graphics.scale(config.scaleFactor)
  groups.hud.drawAll()
  groups.gui.drawAll()
  love.graphics.pop()

  groups.system.drawAll()
end

--[[
  run tests after everything is loaded since some tests
  since some of the tests rely on the game loop
]]
if config.isDebug then
  require 'modules.test.index'
  require 'utils.test.index'
  require '_debug'
end