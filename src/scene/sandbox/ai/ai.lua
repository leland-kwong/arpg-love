local socket = require 'socket'
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
local round = require 'utils.math'.round
local flowFieldtest = require 'scene.sandbox.ai.flow-field-test'

flowFieldtest.create()

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

function Ai.new(gridX, gridY, speed)
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
    speed = speed,
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
  self.ai = Ai.new(24, 15, 100)

  self.player = {
    x = gridPosition(24),
    y = gridPosition(5),
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
):addToWorld(collisionWorlds.map)

-- adds a temporary object to the world to do a quick collision check
local function tempCollisionCheck(world, x1, y1, w, h, x2, y2, filter)
  tempCollisionObject:update(x1, y1, w, h)
  local actualX, actualY, cols, len =
    tempCollisionObject:check(x2, y2, filter)
  return actualX, actualY, cols, len
end

local function getLineOfSight(collisionWorld, x1, y1, x2, y2, filter)
  local ts = socket.gettime()
  local a, b, cols, len
  for i=1, 100 do
    a, b, cols, len = tempCollisionCheck(collisionWorld, x1, y1, 1, 1, x2, y2, filter)
  end
  -- print('vision check', (socket.gettime() - ts) * 1000)
  return len == 0
end

-- ai will move until the last known path using raycasting to check visibility.
-- self [table] - the ai object to move
local function aiPathing(self, target, dt)
  local hasTargetMoved = target.x ~= self.lastTargetX or target.y ~= self.lastTargetY
  self.lastTargetX = target.x
  self.lastTargetY = target.y

  local centerOffset = config.gridSize/2
  local ax, ay = gridPosition(self.x, true), gridPosition(self.y, true)
  local tx, ty = gridPosition(target.x, true), gridPosition(target.y, true)

  -- ai center point
  local caix, caiy = self.x + centerOffset, self.y + centerOffset
  -- target center point
  local ctx, cty = target.x + centerOffset, target.y + centerOffset

  local isNewEndPt = false
  if self.positionTween then
    local d = self.destination
    local diffX, diffY = abs(ctx - d.x), abs(cty - d.y)
    local changeThreshold = 5
    isNewEndPt = diffX > changeThreshold or diffY > changeThreshold
  end

  if hasTargetMoved or isNewEndPt then
    -- check for vision of player using collision check to target
    local canSeeTarget = getLineOfSight(
      collisionWorlds.map,
      caix, caiy,
      ctx, cty,
      subPathCollisionFilter
    )
    if canSeeTarget then
      local endX, endY = ctx, cty
      local dist = require'utils.math'.dist
      local duration = dist(self.x, self.y, endX, endY) / (self.speed)
      self.destination = {x = endX, y = endY}
      self.positionTween = tween.new(duration, self, self.destination, tween.easing.linear)
    end
  end

  if self.positionTween then
    local arrived = self.positionTween:update(dt)
    local nextX, nextY = self.x, self.y
    local actualX, actualY, cols, len = self.collisionObject:move(
      nextX, nextY
    )

    -- if there is a wall collision, adjust our path
    if len > 0 then
      local collision = cols[1]
      -- print(socket.gettime(), 'hit')
    end

    self:drawPath(caix, caiy, self.destination.x, self.destination.y)

    if (arrived) then
      self.positionTween = nil
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
    else
      local size = tileSize - 1
      love.graphics.setColor(0,0,0.2,1)
      love.graphics.rectangle(
        'fill',
        screenX + 1,
        screenY + 1,
        size,
        size
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
