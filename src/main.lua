require 'modules.test.index'
local player = require 'components.player'
local collisionTest = require 'components.collision-test'
local groups = require 'components.groups'
local functional = require 'utils.functional'

player.create()
collisionTest.create()

function pprint(v)
  local inspect = require 'utils.inspect'
  print(inspect(v))
end

function love.load()
  love.window.setTitle('pathfinder')
end

-- function love.keypressed(key, scanCode, isRepeated)
--   if not isRepeated then
--     print(key)
--   end
-- end

function love.update(dt)
  groups.all.updateAll(dt)
end

function love.draw()
  -- background
  love.graphics.clear(0.2,0.2,0.2)
  groups.all.drawAll()
end