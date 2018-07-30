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
local config = require 'config'

console.create()
local player = Player.create()
collisionTest.create()

function love.load()
  local scale = config.scaleFactor
  local resolution = config.resolution
  local vw, vh = resolution.w * scale, resolution.h * scale
  love.window.setMode(vw, vh)
  camera
    :setSize(vw, vh)
    :setScale(scale)
  love.window.setTitle('pathfinder')
end

function love.update(dt)
  groups.all.updateAll(dt)
  camera:setPosition(player.x, player.y)
  groups.gui.updateAll(dt)
end

-- BENCHMARKING
-- local perf = require 'utils.perf'
-- local TestFactory = groups.all.createFactory({})
-- local bench = perf({
--   done = function(t)
--     print('update', t)
--   end
-- })(function()
--   for i=1, 100 do
--     TestFactory.create({})
--   end
-- end)

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
  groups.all.drawAll()
  camera:detach()
  groups.gui.drawAll()
end
