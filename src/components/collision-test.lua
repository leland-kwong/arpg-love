local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local color = require 'modules.color'
local perf = require 'utils.perf'
local camera = require 'components.camera'

local time = 0
local updateCount = 0
local avgTime = 0

local function extract(t, key1, key2, key3, key4, key5, key6)
  return
    t[key1],
    t[key2],
    t[key3],
    t[key4],
    t[key5],
    t[key6]
end

local mouseCollisionFilter = function(item, other)
  return (other.type == 'player') and 'slide' or false
end

local CollisionTest = {
  getInitialProps = function()
    return {}
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
      w = 16,
      h = 16
    }

    self.B = B
    world:add(B, B.x, B.y, B.w, B.h)

    self.obstacles = {}

    for i=1, 10 do
      local obstacle = {
        name = "obstacle_"..i,
        type = 'obstacle',
        x = math.random( 0, love.graphics.getWidth() ),
        y = math.random( 0, love.graphics.getHeight() ),
        w = math.random(20, 30),
        h = math.random(20, 30),
      }
      world:add(obstacle, obstacle.x, obstacle.y, obstacle.w, obstacle.h)
      self.obstacles[i] = {
        draw = coroutine.wrap(function()
          local gfx = love.graphics
          local o = obstacle
          local mode = 'fill'
          local color1 = {0,0.7,1,1}
          while true do
            gfx.setColor(color1)
            gfx.rectangle(
              mode,
              o.x,
              o.y,
              o.w,
              o.h
            )
            coroutine.yield()
          end
        end)
      }
    end
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
    -- remove A and B from the world
    -- world:remove(A)
    -- world:remove(B)
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
    gfx.rectangle(
      'fill',
      self.B.x,
      self.B.y,
      self.B.w,
      self.B.h
    )
  end
}

return groups.all.createFactory(CollisionTest)