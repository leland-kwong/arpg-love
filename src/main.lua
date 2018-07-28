require 'modules.test.index'
require 'components.player'
local groups = require 'components.groups'
local functional = require 'utils.functional'

function pprint(v)
  local inspect = require 'utils.inspect'
  print(inspect(v))
end

function love.load()
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