local groups = require 'components.groups'
local pprint = require 'utils.pprint'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local pathfinder = require 'utils.search-path'
local iterateGrid = require 'utils.iterate-grid'
local getDirection = require 'utils.position'.getDirection
local pathObstacles = require 'utils.path-obstacles'
local tween = require 'modules.tween'
local config = require 'config'
local camera = require 'components.camera'

local AiTest = {}

-- grid generated with https://stackblitz.com/edit/pathfinding-simplify?file=index.js
local grid = {{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,1,1,1,1,1,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,1,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}}

local WALKABLE = 0
local OBSTACLE = 1

-- returns values in pixels with optional grid unit parameter
local function gridPositionConverter(gridSize)
  local round = require 'utils.math'.round
  return function(position, toGridUnits)
    if toGridUnits then
      return round(
        position / gridSize
      )
    end
    return round(position) * gridSize
  end
end

local gridPosition = gridPositionConverter(config.gridSize)

local Move = {}
local getDist = require 'utils.math'.dist
function Move:update(dt)
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
    self.positionTween = tween.new(duration, self, path, 'linear')
  end
  self.lastPathIndex = self.pathIndex
  self.positionTween:update(dt)
  if self.x == x2 and self.y == y2 then
    self.pathIndex = self.pathIndex + 1
  end
  return self.x, self.y
end

local function moveToPosition(x1, y1, path, speed)
  local pos = {
    x = x1,
    y = y1,
    path = path,
    lastPathIndex = 0,
    pathIndex = 1,
    done = false,
    speed = speed
  }
  setmetatable(pos, Move)
  Move.__index = Move
  return pos
end

function AiTest.init(self)
  local enemySize = config.gridSize
  local ai = {
    x = gridPosition(4),
    y = gridPosition(2),
    w = enemySize,
    h = enemySize,
    speed = 50
  }
  self.ai = ai
  ai.collisionObject = collisionObject:new(
    'ai',
    ai.x,
    ai.y,
    ai.w,
    ai.h
  ):addToWorld(collisionWorlds.map)

  self.player = {
    x = gridPosition(2),
    y = gridPosition(2),
    w = config.gridSize,
    h = config.gridSize,
    speed = 200
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

local aiPathCanvas = love.graphics.newCanvas()
local function clearAiPathCanvas()
  -- clear canvas
  love.graphics.setCanvas(aiPathCanvas)
  love.graphics.clear(1,1,1,0)
  love.graphics.setCanvas()
end

local function drawAiPath(...)
  love.graphics.setCanvas(aiPathCanvas)
  love.graphics.clear(1,1,1,0)
  love.graphics.setColor(0,1,1,1)
  love.graphics.setLineStyle('rough')
  love.graphics.line(...)
  love.graphics.setCanvas()
end

local function subPathCollisionFilter(item, other)
  if other.group == 'player' then
    return false
  end
  return 'slide'
end

-- ai will move until the last known path using raycasting to check visibility.
local function aiPathing(self, dt)
  local hasPlayerMoved = self.player.x ~= self.lastPlayerX or self.player.y ~= self.lastPlayerY
  self.lastPlayerX = self.player.x
  self.lastPlayerY = self.player.y

  if getDist(self.ai.x, self.ai.y, self.player.x, self.player.y) <= 22 then
    self.aiMover = nil
    return
  end

  local centerOffset = config.gridSize/2
  local ax, ay = gridPosition(self.ai.x, true), gridPosition(self.ai.y, true)
  local px, py = gridPosition(self.player.x, true), gridPosition(self.player.y, true)
  local hasObstacles = pathObstacles(grid, ax, ay, px, py, WALKABLE)
  -- ai center point
  local caix, caiy = self.ai.x + centerOffset, self.ai.y + centerOffset
  -- player center point
  local cpx, cpy = self.player.x + centerOffset, self.player.y + centerOffset
  if hasPlayerMoved then
    if not hasObstacles then
      local path = {
        {
          x = cpx,
          y = cpy
        }
      }

      local actualX, actualY, cols, len = self.ai.collisionObject:check(
        cpx, cpy
      )
      local isValidPath = true
      if len > 0 then
        if cols[1].other.group == 'wall' then
          local normal = cols[1].normal
          local newPoint = {x = path[1].x, y = path[1].y}
          -- -- add a point perpendicular to the normal and end point
          if normal.x ~= 0 then
            newPoint.x = actualX
          end
          if normal.y ~= 0 then
            newPoint.y = actualY
          end
          -- if this new point collides, then we invalidate the new path
          if (path[1].x ~= newPoint.x) or (path[1].y ~= newPoint.y) then
            local obj = collisionObject:new(
              'faux-ai',
              newPoint.x,
              newPoint.y,
              config.gridSize,
              config.gridSize
            ):addToWorld(collisionWorlds.map)
            local actualX,
                  actualY,
                  cols,
                  len = obj:check(path[1].x, path[1].y, subPathCollisionFilter)
            obj:removeFromWorld(collisionWorlds.map)
            isValidPath = len == 0
          end
          if isValidPath then
            table.insert(path, 1, newPoint)
          end
        end
      end

      if isValidPath then
        self.aiMover = moveToPosition(
          caix, caiy,
          path,
          self.ai.speed,
          gridPosition
        )
      end
    end
  end

  if self.aiMover then
    local newX, newY = self.aiMover:update(dt)
    if self.aiMover.done then
      self.aiMover = nil
    -- update ai position
    else
      self.ai.x = newX - centerOffset
      self.ai.y = newY - centerOffset
      self.ai.collisionObject:update(
        self.ai.x,
        self.ai.y,
        self.ai.w,
        self.ai.h
      )

      local p = self.aiMover.path
      if p[2] then
        drawAiPath({
          caix,
          caiy,
          p[1].x,
          p[1].y,
          p[2].x,
          p[2].y
        })
      else
        drawAiPath(
          caix,
          caiy,
          p[1].x,
          p[1].y
        )
      end
    end
  end

end

function AiTest.update(self, dt)
  playerMovement(self.player, dt)
  aiPathing(self, dt)

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
  love.graphics.draw(aiPathCanvas)
end

return groups.debug.createFactory(AiTest)
