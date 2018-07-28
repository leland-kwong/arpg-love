-- NOTE: this may or may not increase performance. [reference](https://love2d.org/forums/viewtopic.php?f=5&t=82562)
require 'components.player'
local perf = require 'utils.perf'
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