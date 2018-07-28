local groups = require 'components.groups'
local color = require 'modules.color'
local perf = require 'utils.perf'

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

local factory = groups.all.createFactory({
  getInitialProps = function()
    return {}
  end,

  init = function(self)
    local bump = require 'modules.bump'

    -- The grid cell size can be specified via the initialize method
    -- By default, the cell size is 64
    local world = bump.newWorld(50)
    self.world = world

    local B = {
      name = "B",
      collided = false,
      x = love.mouse.getX(),
      y = love.mouse.getY(),
      w = 16,
      h = 16
    }

    self.B = B
    world:add(B, B.x, B.y, B.w, B.h)

    self.obstacles = {}

    for i=1, 10 do
      local obstacle = {
        name = "obstacle_"..i,
        x = math.random( 0, love.graphics.getWidth() ),
        y = math.random( 0, love.graphics.getHeight() ),
        w = 20,
        h = 20,
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
    local posX = love.mouse.getX() - self.B.w/2
    local posY = love.mouse.getY() - self.B.h/2
    -- Try to move B to 0,64. If it collides with A, "slide over it"
    local actualX, actualY, cols, len = self.world:move(self.B, posX, posY)
    self.B.x = actualX
    self.B.y = actualY
    self.B.collided = false

    -- prints the new coordinates of B: 0, -32, 32, 32
    -- print(self.world:getRect(self.B))

    self.cols = self.cols or {}
    -- prints "Collision with A"
    for i=1,len do -- If more than one simultaneous collision, they are sorted out by proximity
      local col = cols[i]
      -- pprint(col)
      self[col.item.name].collided = true

      local curCol = self.cols[i]
      if curCol then
        -- pprint(curCol)
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

    local colorA = {0,0.7,1,1}
    gfx.setColor(colorA)
    for i=1, #self.obstacles do
      local rect = self.obstacles[i]
      rect.draw()
    end
    gfx.setColor(1,1,1,1)

    gfx.print(
      'collision perf: '..avgTime,
      0,
      0
    )
  end
})

return factory