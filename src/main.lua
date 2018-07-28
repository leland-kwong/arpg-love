require 'modules.test.index'
require 'components.player'
local groups = require 'components.groups'

function love.load()
end

function love.update(dt)
  groups.all.updateAll(dt)
end

function love.draw()
  -- background
  love.graphics.clear(0.2,0.2,0.2)
  groups.all.drawAll()
end