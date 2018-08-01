local animationFactory = require 'components.animation-factory'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local color = require 'modules.color'
local perf = require 'utils.perf'
local camera = require 'components.camera'
local iterateGrid = require 'utils.iterate-grid'
local config = require 'config'

local time = 0
local updateCount = 0
local avgTime = 0

local mouseCollisionFilter = function(item, other)
  return false
  -- return (other.type == 'player') and 'slide' or false
end

local CollisionTest = {
  map = {
    {}
  },

  drawOrder = function()
    return 2
  end,

  init = function(self)
    local world = collisionWorlds.map
    local map = self.map
    self.world = world

    local mx, my = camera:getMousePosition()
    local B = {
      name = "B",
      collided = false,
      x = mx,
      y = my,
      w = 8,
      h = 8
    }

    self.B = B
    world:add(B, B.x, B.y, B.w, B.h)

    self.obstacles = {}

    local i = 1

    iterateGrid(map.grid, function(v, x, y)
      local gridSize = config.gridSize
      local tileX, tileY = x * gridSize, y * gridSize
      if self.walkable == v then
        return
      end
      local obstacle = {
        name = "obstacle_"..i,
        type = 'obstacle',
        x = tileX,
        y = tileY,
        w = gridSize,
        h = gridSize,
      }
      world:add(obstacle, obstacle.x, obstacle.y, obstacle.w, obstacle.h)
      i = i + 1
    end)
  end,

  update = perf({
    done = function(timeTaken)
      time = time + timeTaken
      updateCount = updateCount + 1
      avgTime = time / updateCount
    end
  })(function(self, dt)
    -- print(camera:getBounds())

    local mx, my = camera:getMousePosition()
    local posX = mx - self.B.w/2
    local posY = my - self.B.h/2
    local actualX, actualY, cols, len = self.world:move(self.B, posX, posY, mouseCollisionFilter)
    self.B.x = actualX
    self.B.y = actualY
    self.B.collided = false

    -- set collision states
    self.cols = self.cols or {}
    for i=1,len do
      local col = cols[i]
      self[col.item.name].collided = true

      local curCol = self.cols[i]
      if curCol then
      end
      self.cols[i] = col
    end

    local collisionStateChanged = self.previouslyCollided ~= self.B.collided
    if collisionStateChanged then
      -- reset perf time
      time = 0
      updateCount = 0
    end
    self.previouslyCollided = self.B.collided

    for i=1, #self.obstacles do
      local rect = self.obstacles[i]
      rect.advanceFrame(dt)
    end
  end),

  draw = function(self)
    local gfx = love.graphics

    local collisionTint = {1,1,0,1}
    local colorB = {1,0.5,1,1}
    if self.B.collided then
      colorB = color.multiply(colorB, collisionTint)
    end
    gfx.setColor(colorB)
    local mx, my = camera:getMousePosition()
    gfx.rectangle(
      'fill',
      -- recenter
      mx - self.B.w/2,
      my - self.B.h/2,
      self.B.w,
      self.B.h
    )
  end
}

return groups.all.createFactory(CollisionTest)