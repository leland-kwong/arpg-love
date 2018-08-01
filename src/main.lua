require 'lua_modules.strict'
require 'modules.test.index'
local console = require 'modules.console'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Player = require 'components.player'
local groups = require 'components.groups'
local functional = require 'utils.functional'
local cloneGrid = require 'utils.clone-grid'
local perf = require 'utils.perf'
local camera = require 'components.camera'
local config = require 'config'
local Map = require 'modules.map-generator.index'
local Minimap = require 'components.map.minimap'
local MainMap = require 'components.map.main-map'
require 'components.map.minimap'

local map = Map.createAdjacentRooms(4, 20)
local WALKABLE = 1
local gridTileTypes = {
  -- unwalkable
  [0] = {
    'wall',
    'wall-2',
    'wall-3'
  },
  -- walkable
  [1] = {
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-1',
    'floor-2',
    'floor-3'
  }
}
local gridTileDefinitions = cloneGrid(map.grid, function(v, x, y)
  local tileGroup = gridTileTypes[v]
  return tileGroup[math.random(1, #tileGroup)]
end)

local scale = config.scaleFactor
console.create()
local player = Player.create()

Minimap.create({
  camera = camera,
  grid = map.grid
})

MainMap.create({
  camera = camera,
  grid = map.grid,
  tileRenderDefinition = gridTileDefinitions,
  walkable = WALKABLE
})

function love.load()
  local resolution = config.resolution
  local vw, vh = resolution.w * scale, resolution.h * scale
  love.window.setMode(vw, vh)
  camera
    :setSize(vw, vh)
    :setScale(scale)
  love.window.setTitle('pathfinder')
  msgBus.send(msgBus.GAME_LOADED)
end

function love.update(dt)
  groups.all.updateAll(dt)
  groups.debug.updateAll(dt)
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
