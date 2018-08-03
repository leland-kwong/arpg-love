local groups = require 'components.groups'
local pprint = require 'utils.pprint'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local pathfinder = require 'utils.search-path'
local iterateGrid = require 'utils.iterate-grid'
local getDirection = require 'utils.position'.getDirection
local pathObstacles = require 'utils.path-obstacles'
local memoize = require 'utils.memoize'
local tween = require 'modules.tween'
local config = require 'config'
local camera = require 'components.camera'

local AiTest = {}

-- grid generated with https://stackblitz.com/edit/pathfinding-simplify?file=index.js
local grid = {{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,1,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}}

local WALKABLE = 0
local OBSTACLE = 1

-- returns values in pixels with optional grid unit parameter
local function gridPositionConverter(gridSize)
  local round = require 'utils.math'.round
  return function(position, toGridUnits)
    if toGridUnits then
      return round(
        math.ceil(position / gridSize)
      )
    end
    return round(position) * gridSize
  end
end

local gridPosition = gridPositionConverter(config.gridSize)

local Positioner = {}
Positioner.__index = Positioner

local getDirection = require 'utils.position'.getDirection
local abs = math.abs
function Positioner:update(dt, speed)
  local dx = speed * dt * self.dirX
  local dy = speed * dt * self.dirY
  self.x = self.x + dx
  self.y = self.y + dy
  if (abs(self.x - self.x2) <= self.stopDistance) and
    (abs(self.y - self.y2) <= self.stopDistance) then
      self.done = true
      return nil
  end
  return self.x, self.y
end

function Positioner.new(x1, y1, x2, y2, stopDistance)
  local dirX, dirY = getDirection(x1, y1, x2, y2)
  return setmetatable({
    x = x1,
    y = y1,
    x2 = x2,
    y2 = y2,
    stopDistance = stopDistance,
    dirX = dirX,
    dirY = dirY,
    done = false,
  }, Positioner)
end

local enemySize = config.gridSize
local Ai = {}
local Ai_mt = {__index = Ai}

function Ai.new(gridX, gridY)
  local w, h = enemySize, enemySize
  local x, y = gridPosition(gridX), gridPosition(gridY)
  local colObj = collisionObject:new(
    'ai',
    x,
    y,
    w,
    h
  ):addToWorld(collisionWorlds.map)

  return setmetatable({
    x = x,
    y = y,
    w = w,
    h = h,
    speed = 100,
    collisionObject = colObj
  }, Ai_mt)
end

function Ai:drawPath(...)
  self.canvas = self.canvas or love.graphics.newCanvas()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(1,1,1,0)
  love.graphics.setColor(0,1,1,1)
  love.graphics.setLineStyle('rough')
  love.graphics.line(...)
  love.graphics.setCanvas()
end

function AiTest.init(self)
  self.ai = Ai.new(24, 15)

  self.player = {
    x = gridPosition(24),
    y = gridPosition(2),
    w = config.gridSize,
    h = config.gridSize,
    speed = 250
  }
  self.player.collisionObject = collisionObject:new(
    'player',
    self.player.x,
    self.player.y,
    self.player.w,
    self.player.h
  ):addToWorld(collisionWorlds.map)

  local function setupWallCollisionObjects(v, x, y)
    if v == OBSTACLE then
      local size = config.gridSize
      local obj = collisionObject:new(
        'wall',
        x * size,
        y * size,
        size,
        size
      ):addToWorld(collisionWorlds.map)
    end
  end
  iterateGrid(grid, setupWallCollisionObjects)
end

local function playerMovement(player, dt)
  local moveAmount = player.speed * dt
  local dx, dy = 0, 0

  if love.keyboard.isDown('d') then
    dx = dx + moveAmount
  end

  if love.keyboard.isDown('a') then
    dx = dx - moveAmount
  end

  if love.keyboard.isDown('w') then
    dy = dy - moveAmount
  end

  if love.keyboard.isDown('s') then
    dy = dy + moveAmount
  end

  if dx ~= 0 or dy ~= 0 then
    local ax, ay = player.collisionObject:move(
      player.x + dx,
      player.y + dy,
      function(item, other)
        if other.group == 'wall' or other.group == 'ai' then
          return 'slide'
        end
        return false
      end
    )

    player.x = ax
    player.y = ay
  end
end

local function subPathCollisionFilter(item, other)
  if other.group == 'wall' then
    return 'slide'
  end
  return false
end

local abs = math.abs

local tempCollisionObject = collisionObject:new(
  'TempCollisionObject',
  0,
  0,
  1,
  1
)

-- adds a temporary object to the world to do a quick collision check
local function tempCollisionCheck(world, x1, y1, w, h, x2, y2, filter)
  tempCollisionObject:addToWorld(world)
  tempCollisionObject:update(x1, y1, w, h)
  local actualX, actualY, cols, len =
    tempCollisionObject:check(x2, y2, filter)
  tempCollisionObject:removeFromWorld(world)
  return actualX, actualY, cols, len
end

-- ai will move until the last known path using raycasting to check visibility.
-- self [table] - the ai object to move
local function aiPathing(self, target, dt)
  local hasTargetMoved = target.x ~= self.lastTargetX or target.y ~= self.lastTargetY
  self.lastTargetX = target.x
  self.lastTargetY = target.y

  local isNewEndPt = false
  if self.moving then
    isNewEndPt = (target.x ~= self.x2) or (target.y ~= self.y2)
  end

  local centerOffset = config.gridSize/2
  local ax, ay = gridPosition(self.x, true), gridPosition(self.y, true)
  local tx, ty = gridPosition(target.x, true), gridPosition(target.y, true)

  -- ai center point
  local caix, caiy = self.x + centerOffset, self.y + centerOffset
  -- target center point
  local ctx, cty = target.x + centerOffset, target.y + centerOffset

  if hasTargetMoved or isNewEndPt then
    local hasObstacles = false
    -- local hasObstacles = pathObstacles(grid, ax, ay, tx, ty, WALKABLE)
    if not hasObstacles then
      self.path = {
        {ctx, cty}
      }
      self.pathIndex = 1

      -- local isDirectPath = true
      local actualX, actualY, cols, len = tempCollisionCheck(
        collisionWorlds.map,
        caix, caiy, self.w, self.h,
        ctx, cty,
        function(item, other)
          if other.group == 'wall' then
            return 'slide'
          end
          return false
        end
      )
      local isDirectPath = len == 0
      print('direct path:', isDirectPath)
      if not isDirectPath then
        local newPath = pathfinder(grid, {ax, ay}, {tx, ty}, WALKABLE)
        if newPath then
          -- pprint(newPath)
          local functional = require 'utils.functional'
          local convertToPixels = function(path, point, i)
            path[i] = {gridPosition(point[1]), gridPosition(point[2])}
            -- point[1] = gridPosition(point[1]) + centerOffset
            -- point[2] = gridPosition(point[2]) + centerOffset
            return path
          end
          local convertedPath = functional.reduce(newPath, convertToPixels, {})
          -- pprint(convertedPath)
          self.path = convertedPath
          self.pathIndex = 2
        end
      end

      self.moving = true
    end
  end

  if self.moving then
    local point = self.path[self.pathIndex]
    local x2, y2 = point[1], point[2]
    local dirX, dirY = require 'utils.position'.getDirection(self.x, self.y, x2, y2)

    -- distance to move this frame
    local dist = self.speed * dt
    local dx, dy = dist * dirX, dist * dirY
    local centerOffset = config.gridSize / 2
    local nextX, nextY = self.x + dx, self.y + dy
    local actualX, actualY, cols, len = self.collisionObject:move(
      nextX, nextY
    )

    if len > 0 then
      -- when we hit a corner, there are times where it will get stuck at that corner due to some issue with the
      -- way `slide` collision works. The logic here solves that issue by making sure the slide amount is always the intended speed
      if cols[1].normal.y ~= 0 then
        local actualDx = math.abs(actualX - self.x)
        if actualDx < dist then
          local slideDirection = actualX - self.x < 0 and -1 or 1
          actualX = self.x + slideDirection * dist
        end
      end

      if cols[1].normal.x ~= 0 then
        local actualDy = math.abs(actualY - self.y)
        if actualDy < dist then
          local slideDirection = actualY - self.y < 0 and -1 or 1
          actualY = self.y + slideDirection * dist
        end
      end
    end

    self.x = actualX
    self.y = actualY

    local stopThreshold = 30
    local centerOffset = 8

    self:drawPath(
      caix,
      caiy,
      x2,
      y2
    )

    if (
      abs(self.x - x2) <= stopThreshold and
      abs(self.y - y2) <= stopThreshold
    ) then
      self.pathIndex = self.pathIndex + 1
      self.moving = self.pathIndex <= #self.path
    end
  end

end

local perf = require 'utils.perf'
aiPathing = perf({
  done = function(t)
    -- print('pathfind:', t)
  end
})(aiPathing)

function AiTest.update(self, dt)
  playerMovement(self.player, dt)
  aiPathing(self.ai, self.player, dt)

  camera:setPosition(self.player.x, self.player.y)
end

function AiTest.draw(self)
  iterateGrid(grid, function(v, x, y)
    local tileSize = config.gridSize
    local screenX, screenY = x * tileSize, y * tileSize
    if v == OBSTACLE then
      love.graphics.setColor(0.75,0.75,0.75,1)
      love.graphics.rectangle(
        'fill',
        screenX,
        screenY,
        tileSize,
        tileSize
      )
    end
  end)

  local ai = self.ai
  love.graphics.setColor(0.5,0.5,1,1)
  love.graphics.rectangle(
    'fill',
    ai.x,
    ai.y,
    ai.w,
    ai.h
  )

  local player = self.player
  love.graphics.setColor(1,1,0,1)
  love.graphics.rectangle(
    'fill',
    player.x,
    player.y,
    player.w,
    player.h
  )

  love.graphics.setColor(1,1,1,1)
  if ai.canvas then
    love.graphics.draw(ai.canvas)
  end
end

return groups.debug.createFactory(AiTest)
