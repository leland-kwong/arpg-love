local Component = require 'modules.component'
local Grid = require 'utils.grid'
local bump = require 'modules.bump'
local camera = require 'components.camera'
local Math = require 'utils.math'
local Position = require 'utils.position'
local FlowField = LiveReload 'modules.flow-field'

local gridSize = 16
local cw = bump.newWorld(gridSize)
local WALL = 1

local flowField = FlowField(function(grid, x, y)
  local v = Grid.get(grid, x, y)
  return v == 0
end)

local getMousePosition = function()
  local mx, my = love.mouse.getPosition()
  return mx/camera.scale, my/camera.scale
end

local makeObj = function(x, y)
  local size = math.random(1, 1) * 8
  return {
    x = x or 0,
    y = y or 0,
    dx = 0,
    dy = 0,
    w = size,
    h = size,
    id = 'obj1',
    group = 'ai',
    velocity = math.random(2, 4)
  }
end
local aiObjects = {}
for i=1, 32 do
  local obj = makeObj(getMousePosition())
  table.insert(aiObjects, obj)
  cw:add(obj, obj.x, obj.y, obj.w, obj.h)
end

local function drawInfluenceLines(self)
  love.graphics.setColor(0,1,1,0.4)
  for _,p in ipairs(self.obstaclePoints) do
    love.graphics.line(p.x, p.y, p.x2, p.y2)

    -- love.graphics.push()
    -- love.graphics.origin()
    -- love.graphics.print(
    --   string.format('%.1f', p.influence),
    --   p.x * camera.scale,
    --   p.y * camera.scale
    -- )
    -- love.graphics.pop()
  end
end

local renderFlowField = function(ff)
  -- love.graphics.push()
  -- love.graphics.origin()
  local AnimationFactory = require 'components.animation-factory'
  local arrow = AnimationFactory:newStaticSprite('gui-arrow-small')
  Grid.forEach(ff, function(v, x, y)
    local angle = string.format('%.1f', math.atan2(v.y, v.x)) + math.pi/2
    local x,y = x * gridSize + (gridSize/2), y * gridSize + (gridSize/2)
    if v.isModified then
      love.graphics.setColor(1,1,0)
    elseif v.hasForces then
      love.graphics.setColor(1,0.2,1)
    else
      love.graphics.setColor(0,1,1)
    end
    arrow:draw(x, y, angle)
  end)
  -- love.graphics.pop()
end

Component.create({
  id = 'pathingAvoidanceTest',
  -- group = 'gui',
  clock = 0,
  init = function(self)
    self.grid = {
      {1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1},
      {1,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1},
      {1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
      {1,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,1},
    }
    Grid.forEach(self.grid, function(v, x, y)
      if v == WALL then
        cw:add({
          group = 'wall',
          x = x * gridSize,
          y = y * gridSize,
          w = gridSize,
          h = gridSize
        }, x * gridSize, y * gridSize, gridSize, gridSize)
      end
    end)
  end,
  update = function(self, dt)
    self.clock = self.clock + dt

    local mx, my = getMousePosition()
    self.obstaclePoints = {}
    for i=1, #aiObjects do
      local obj = aiObjects[i]

      local distFromTarget = Math.dist(obj.x, obj.y, mx, my)
      local dx, dy = Position.getDirection(obj.x, obj.y, mx, my)
      local influenceSize = 80
      local queryX, queryY = math.floor(obj.x - influenceSize/2 + obj.w/2), math.floor(obj.y - influenceSize/2 + obj.h/2)
      local items,len = cw:queryRect(queryX, queryY, influenceSize, influenceSize, function(item)
        return (item ~= obj) and
          (
            item.group == 'wall' or
            item.group == 'ai'
          )
      end)
      for i=1, len do
        local item = items[i]
        local objX, objY = obj.x, obj.y
        local x,y = Math.nearestBoxPoint(objX, objY, item.x, item.y, item.w, item.h)
        local dx2, dy2 = Position.getDirection(objX, objY, x, y)
        local dist = Math.dist(objX, objY, x, y)
        local maxInfluence = item.group == 'wall' and 2 or 1
        local influence = dist <= 10 and maxInfluence or 0
        table.insert(self.obstaclePoints, {
          x = objX,
          y = objY,
          x2 = x,
          y2 = y,
          dx = dx2,
          dy = dy2,
          influence = influence
        })
        dx = dx + (- dx2 * math.max(0, influence - (item.dx or 0)))
        dy = dy + (- dy2 * math.max(0, influence - (item.dy or 0)))
      end
      dx, dy = Math.normalizeVector(dx, dy)
      obj.dx, obj.dy = dx, dy
      obj.x, obj.y = obj.x + obj.dx * obj.velocity, obj.y + obj.dy * obj.velocity
      cw:update(obj, obj.x, obj.y)
    end
  end,
  draw = function(self)
    local g = love.graphics
    Grid.forEach(self.grid, function(v, x, y)
      if v == WALL then
        g.setColor(1,1,1)
        g.rectangle('line', x * gridSize, y * gridSize, gridSize, gridSize)
      end
    end)

    local mx, my = getMousePosition()
    love.graphics.setColor(1,1,0)
    love.graphics.rectangle('fill', mx - gridSize/2, my - gridSize/2, gridSize, gridSize)

    -- drawInfluenceLines(self)

    for i=1, #aiObjects do
      local obj = aiObjects[i]

      -- obstacle check area
      -- love.graphics.setColor(1,1,1,0.1)
      -- local size = gridSize * 4
      -- local offset = -size/2 + obj.w/2
      -- love.graphics.rectangle('fill', obj.x + offset, obj.y + offset, size, size)

      love.graphics.setColor(1,0,1)
      love.graphics.rectangle('line', obj.x, obj.y, obj.w, obj.w)
    end
  end
})