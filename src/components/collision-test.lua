local animationFactory = require 'components.animation-factory'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local color = require 'modules.color'
local perf = require 'utils.perf'
local camera = require 'components.camera'
local Map = require 'modules.map-generator.index'
local iterateGrid = require 'utils.iterate-grid'
local config = require 'config'

local map = Map.createAdjacentRooms(4, 15)
local time = 0
local updateCount = 0
local avgTime = 0

local mouseCollisionFilter = function(item, other)
  return false
  -- return (other.type == 'player') and 'slide' or false
end

local floorTileTypes = {
  'floor',
  'floor',
  'floor',
  'floor',
  'floor',
  'floor',
  'floor',
  'floor-1',
  'floor-2'
}
local FloorTile = {
  init = function(self)
    self.animation = animationFactory.create({
      floorTileTypes[math.random(1, #floorTileTypes)]
    })
  end,

  drawOrder = function()
    return 1
  end,

  update = function(self, dt)
    self.sprite = self.animation.next(dt)
  end,

  draw = function(self)
    local gfx = love.graphics
    gfx.setColor(1,1,1,1)
    gfx.draw(
      animationFactory.spriteAtlas,
      self.sprite,
      self.x,
      self.y,
      0,
      1,
      1,
      0,
      12
    )
  end
}
local FloorTileFactory = groups.all.createFactory(FloorTile)

local CollisionTest = {
  getInitialProps = function()
    return {}
  end,

  drawOrder = function()
    return 2
  end,

  init = function(self)
    local world = collisionWorlds.map
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

    local walkable = 1
    local unwalkable = 0
    local i = 1
    local wallTileTypes = {
      'wall',
      'wall-2',
      'wall-3'
    }

    iterateGrid(map.grid, function(v, x, y)
      local gridSize = config.gridSize
      local tileX, tileY = x * gridSize, y * gridSize
      if walkable == v then
        return FloorTileFactory.create({
          x = tileX,
          y = tileY
        })
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
      local tileAnimation = animationFactory.create({
        wallTileTypes[math.random(1,3)]
      })
      local sprite
      self.obstacles[i] = {
        draw = coroutine.wrap(function()
          local gfx = love.graphics
          local o = obstacle
          while true do
            gfx.setColor(1,1,1,1)
            gfx.draw(
              animationFactory.spriteAtlas,
              sprite,
              o.x,
              o.y,
              0,
              1,
              1,
              0,
              12
            )
            coroutine.yield()
          end
        end),

        advanceFrame = function(dt)
          sprite = tileAnimation.next(dt)
        end
      }
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
    local mx, my = camera:getMousePosition()
    local posX = mx - self.B.w/2
    local posY = my - self.B.h/2
    local actualX, actualY, cols, len = self.world:move(self.B, posX, posY, mouseCollisionFilter)
    self.B.x = actualX
    self.B.y = actualY
    self.B.collided = false

    -- prints the new coordinates of B: 0, -32, 32, 32
    -- print(self.world:getRect(self.B))

    self.cols = self.cols or {}
    -- prints "Collision with A"
    for i=1,len do -- If more than one simultaneous collision, they are sorted out by proximity
      local col = cols[i]
      self[col.item.name].collided = true

      local curCol = self.cols[i]
      if curCol then
      end
      self.cols[i] = col
      -- print(("Collision with %s."):format(col.other.name))
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

    local colorA = {0,0.7,1,1}
    gfx.setColor(colorA)
    for i=1, #self.obstacles do
      local rect = self.obstacles[i]
      rect.draw()
    end
    gfx.setColor(1,1,1,1)

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