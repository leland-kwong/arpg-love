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

local getDist = require 'utils.math'.dist
function Positioner:update(dt)
  local isNewIndex = self.lastPathIndex ~= self.pathIndex
  local done = self.pathIndex > #self.path
  if done then
    self.done = true
    return
  end

  local path = self.path[self.pathIndex]
  local x2, y2 = path.x, path.y
  if isNewIndex then
    local dist = getDist(self.x, self.y, x2, y2)

    if dist == 0 then
      self.done = true
      return
    end

    local duration = dist / self.speed
    self.positionTween = tween.new(duration, self, path, tween.easing.linear)
  end
  self.lastPathIndex = self.pathIndex
  self.positionTween:update(dt)
  if self.x == x2 and self.y == y2 then
    self.pathIndex = self.pathIndex + 1
  end
  return self.x, self.y
end

function Positioner.new(x1, y1, path, speed)
  return setmetatable({
    x = x1,
    y = y1,
    path = path,
    lastPathIndex = 0,
    pathIndex = 1,
    done = false,
    speed = speed
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
    speed = 150,
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
  self.ai = Ai.new(8, 2)

  self.player = {
    x = gridPosition(2),
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

math.randomseed(os.time())
-- ai will move until the last known path using raycasting to check visibility.
-- self [table] - the ai object to move
local function aiPathing(self, target, dt)
  local hasTargetMoved = target.x ~= self.lastTargetX or target.y ~= self.lastTargetY
  self.lastTargetX = target.x
  self.lastTargetY = target.y

  local isNewEndPt = false
  if self.positioner then
    local currentEndPt = self.positioner.path[#self.positioner.path]
    isNewEndPt = (target.x ~= currentEndPt.x) or (target.y ~= currentEndPt.y)
  end

  self.stopDistance = self.stopDistance or 30
  local shouldStopNearTarget = self.positioner and getDist(
    self.x,
    self.y,
    target.x,
    target.y
  ) <= self.stopDistance
  if shouldStopNearTarget then
    self.positioner = nil
    return
  end

  local centerOffset = config.gridSize/2
  local ax, ay = gridPosition(self.x, true), gridPosition(self.y, true)
  local tx, ty = gridPosition(target.x, true), gridPosition(target.y, true)

  -- ai center point
  local caix, caiy = self.x + centerOffset, self.y + centerOffset
  -- target center point
  local ctx, cty = target.x + centerOffset, target.y + centerOffset

  if hasTargetMoved or isNewEndPt then
    local hasObstacles = pathObstacles(grid, ax, ay, tx, ty, WALKABLE)
    if not hasObstacles then
      local path = {
        {
          x = ctx,
          y = cty
        }
      }

      local endX, endY = path[1].x, path[1].y
      local actualX, actualY, cols, len =
        self.collisionObject:check(endX, endY)
      local isValidPath = true
      if len > 0 then
        for i=1, len do
          local col = cols[i]
          if col.other.group == 'wall' or col.other.group == 'ai' then
            local normal = col.normal
            local newPoint = {
              x = endX,
              y = endY
            }
            -- -- add a point perpendicular to the normal and end point
            if normal.x ~= 0 then
              newPoint.x = actualX
            end
            if normal.y ~= 0 then
              newPoint.y = actualY
            end
            -- if this new point collides, then we invalidate the new path
            if (endX ~= newPoint.x) or (endY ~= newPoint.y) then
              local actualX,
                    actualY,
                    cols,
                    len = tempCollisionCheck(
                      collisionWorlds.map,
                      newPoint.x, newPoint.y,
                      config.gridSize, config.gridSize,
                      endX, endY,
                      subPathCollisionFilter
                    )
              isValidPath = len == 0

              -- sometimes the collisions are from hugging the wall, so we handle that here
              if len > 0 then
                -- allowed distance from intended point
                local threshold = config.gridSize/2
                if (
                  abs(actualX - endX) <= threshold and
                  abs(actualY - endY) <= threshold
                ) then
                  isValidPath = true
                end
              end

              if isValidPath then
                table.insert(path, 1, newPoint)
              end
            end
          end
        end
      end

      if isValidPath then
        self.positioner = Positioner.new(
          caix, caiy,
          path,
          self.speed,
          gridPosition
        )
      end
    end
  end

  if self.positioner then
    local newX, newY = self.positioner:update(dt)
    if self.positioner.done then
      self.positioner = nil
    -- update ai position
    else
      self.x = newX - centerOffset
      self.y = newY - centerOffset
      self.collisionObject:update(
        self.x,
        self.y,
        self.w,
        self.h
      )

      local p = self.positioner.path
      if p[2] then
        self:drawPath({
          caix,
          caiy,
          p[1].x,
          p[1].y,
          p[2].x,
          p[2].y
        })
      else
        self:drawPath(
          caix,
          caiy,
          p[1].x,
          p[1].y
        )
      end
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
    if v == OBSTACLE then
      local tileSize = config.gridSize
      love.graphics.setColor(0.75,0.75,0.75,1)
      love.graphics.rectangle(
        'fill',
        x * tileSize,
        y * tileSize,
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
  love.graphics.draw(ai.canvas)
end

return groups.debug.createFactory(AiTest)
