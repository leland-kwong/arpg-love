local Component = require 'modules.component'
local bump = require 'modules.bump'
local Grid = require 'utils.grid'
local config = require 'config.config'
local CollisionGroups = require 'modules.collision-groups'
local groupMatch = LiveReload 'utils.group-match'

local gridSize = 16
local cw = bump.newWorld(gridSize)
local gridTypes = {
  wall = 1
}

local target = {
  x = 9 * gridSize,
  y = 3 * gridSize
}

local startPoint = {
  x = 2 * gridSize,
  y = 2 * gridSize
}

local getMousePosition = function()
  local mx, my = love.mouse.getPosition()
  return mx/config.scale, my/config.scale
end

local defaultFilter = function(item, other)
  return groupMatch(other.group, 'obstacle') and 'slide' or false
end

local tempObj = {}
local getActionPosition = function(startX, startY, targetX, targetY, filter)
  cw:add(tempObj, startX, startY, gridSize, gridSize)
  local actualX, actualY = cw:move(tempObj, targetX, targetY, filter or defaultFilter)
  cw:remove(tempObj)
  return actualX, actualY
end

local group = CollisionGroups.create('obstacle', 'interact')
local groupMatch = LiveReload 'utils.group-match'
local groupB = {'player enemyAi interact', 'obstacle'}
for i=1, 10 do
  local ts = Time()
  for j=1, 100000 do
    -- local matches = CollisionGroups.matches(group, CollisionGroups.create('player', 'enemyAi', 'interact'))
    -- local matches = groupMatch('obstacle interact', 'player enemyAi interact')
    -- local matches = groupMatch('obstacle interact', 'player enemyAi interact') or
    --   groupMatch('obstacle interact', 'obstacle')
    local matches = groupMatch('obstacle interact', {'player', 'enemyAi', 'obstacle'})
  end
  print(Time() - ts)
end

Component.create({
  id = 'actionPositionTesting',
  group = 'gui',
  init = function(self)
    self.grid = {
      {1,1,1,1,1,1,1,1},
      {1,0,0,0,0,0,0,1},
      {1,0,0,0,1,0,0,1},
      {1,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,1,1},
      {1,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,1},
      {1,1,1,1,1,1,1,1},
    }
    Grid.forEach(self.grid, function(v, x, y)
      if gridTypes.wall == v then
        cw:add({
          group = 'obstacle'
        }, x * gridSize, y * gridSize, gridSize, gridSize)
      end
    end)
  end,
  draw = function(self)
    Grid.forEach(self.grid, function(v, x, y)
      if gridTypes.wall == v then
        love.graphics.setColor(1,1,1)
        love.graphics.rectangle('line', x * gridSize, y * gridSize, gridSize, gridSize)
      end
    end)

    love.graphics.setColor(1,1,0)
    love.graphics.rectangle('fill', target.x, target.y, gridSize, gridSize)

    local mx, my = getMousePosition()
    local actionX, actionY = getActionPosition(mx, my, target.x, target.y)
    love.graphics.setColor(1,0,1)
    love.graphics.rectangle('line', actionX, actionY, gridSize, gridSize)

    love.graphics.setColor(0,1,1)
    love.graphics.circle('fill', mx, my, 4)
    love.graphics.rectangle('line', mx, my, gridSize, gridSize)
    love.graphics.line(mx, my, target.x, target.y)
  end,
})