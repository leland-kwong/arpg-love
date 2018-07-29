require 'lua_modules.strict'
require 'modules.test.index'
require 'modules.console'
local msgBus = require 'components.msg-bus'
local player = require 'components.player'
local collisionTest = require 'components.collision-test'
local groups = require 'components.groups'
local functional = require 'utils.functional'

player.create()
collisionTest.create()

function love.load()
  love.window.setTitle('pathfinder')
end

function love.update(dt)
  groups.all.updateAll(dt)
end

local inputMsg = require 'utils.pooled-table'(function(t, key, scanCode, isRepeated)
  t.key = key
  t.code = scanCode
  t.repeated = isRepeated
  return t
end)

function love.keypressed(key, scanCode, isRepeated)
  msgBus.input.send(
    msgBus.input.KEY_PRESSED,
    inputMsg(key, scanCode, isRepeated)
  )
end

function love.keyreleased(key, scanCode)
  msgBus.input.send(
    msgBus.input.KEY_RELEASED,
    inputMsg(key, scanCode, false)
  )
end

function love.draw()
  -- background
  love.graphics.clear(0.2,0.2,0.2)
  groups.all.drawAll()
end