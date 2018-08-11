-- can't use lua strict right now because 'jumper' library uses globals which throws errors
-- require 'lua_modules.strict'

require 'components.run'
require 'modules.test.index'

-- NOTE: this is necessary for crisp pixel rendering
love.graphics.setDefaultFilter('nearest', 'nearest')

local console = require 'modules.console'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local config = require 'config'
local camera = require 'components.camera'
local SceneMain = require 'scene.scene-main'

local scale = config.scaleFactor
console.create()

local scenes = {
  main = SceneMain,
  -- When in production, this module will not get loaded since it will not exist
  sandbox = (function()
    local scene = love.filesystem.load('scene/sandbox/main.lua')
    if scene then
      return scene()
    end
  end)()
}

local globalState = {
  activeScene = scenes.sandbox,
}

function love.load()
  local resolution = config.resolution
  local vw, vh = resolution.w * scale, resolution.h * scale
  love.window.setMode(vw, vh)
  camera
    :setSize(vw, vh)
    :setScale(scale)
  msgBus.send(msgBus.GAME_LOADED)

  globalState.activeScene.create()
end

function love.update(dt)
  groups.all.updateAll(dt)
  groups.debug.updateAll(dt)
  groups.gui.updateAll(dt)
end

local inputMsg = require 'utils.pooled-table'(function(t, key, scanCode, isRepeated)
  t.key = key
  t.code = scanCode
  t.repeated = isRepeated
  return t
end)

function love.keypressed(key, scanCode, isRepeated)
  msgBus.send(
    msgBus.KEY_PRESSED,
    inputMsg(key, scanCode, isRepeated)
  )
end

function love.keyreleased(key, scanCode)
  msgBus.send(
    msgBus.KEY_RELEASED,
    inputMsg(key, scanCode, false)
  )
end

function love.draw()
  camera:attach()
  -- background
  love.graphics.clear(0.2,0.2,0.2)
  groups.all.drawAll()
  groups.debug.drawAll()
  camera:detach()
  groups.gui.drawAll()
end
