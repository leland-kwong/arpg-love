require 'lua_modules.strict'
require 'modules.test.index'
local console = require 'modules.console'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Player = require 'components.player'
local collisionTest = require 'components.collision-test'
local groups = require 'components.groups'
local functional = require 'utils.functional'
local perf = require 'utils.perf'
local camera = require 'components.camera'

local measureFunc = perf({
  done = function(timeTaken)
    print(timeTaken)
  end
})

console.create()
local player = Player.create()
collisionTest.create()

function love.load()
  love.window.setTitle('pathfinder')
end

function love.update(dt)
  -- update the player first to make sure camera info is up to date
  -- before updating all other things
  groups.player.updateAll(dt)
  camera:setPosition(player.x, player.y)

  groups.all.updateAll(dt)
end

-- love.update = measureFunc(love.update)

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
  camera:attach()
  -- background
  love.graphics.clear(0.2,0.2,0.2)
  groups.player.drawAll()
  groups.all.drawAll()
  camera:detach()
end
