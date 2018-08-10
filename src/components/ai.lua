local getAdjacentWalkablePosition = require 'modules.get-adjacent-open-position'
local collisionObject = require 'modules.collision'
local uid = require'utils.uid'
local tween = require 'modules.tween'
local socket = require 'socket'
local distOfLine = require'utils.math'.dist

local Ai = {}
local Ai_mt = {__index = Ai}
local gridSize = nil

function Ai.setGridSize(size)
  gridSize = size
end

-- gets directions from grid position, adjusting vectors to handle wall collisions as needed
local aiPathWithAstar = require'modules.flow-field.pathing-with-astar'
local getPathWithAstar = require'utils.perf'({
  enabled = false,
  done = function(t)
    print('ai path:', t)
  end
})(aiPathWithAstar)

function Ai:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)
  local row = grid[gridY]
  local isInsideWall = (not row) or (row[gridX] ~= self.WALKABLE)

  if isInsideWall then
    local openX, openY = getAdjacentWalkablePosition(grid, gridX, gridY, self.WALKABLE)
    if openX then
      local nextX, nextY = openX * gridSize, openY * gridSize
      self.x = nextX
      self.y = nextY
      self.collision:update(
        self.x,
        self.y,
        self.w,
        self.h
      )
    end
  end
end

local COLLISION_SLIDE = 'slide'
local function collisionFilter()
  return COLLISION_SLIDE
end

function Ai:move(grid, flowField, dt)
  local centerOffset = self.padding
  local prevGridX, prevGridY = self.pxToGridUnits(self.prevX or 0, self.prevY or 0)
  local gridX, gridY = self.pxToGridUnits(self.x, self.y)
  -- we can use this detect whether the agent is stuck if the grid position has remained the same for several frames and was trying to move
  local isNewGridPosition = prevGridX ~= gridX or prevGridY ~= gridY
  local isNewFlowField = self.lastFlowField ~= flowField
  local shouldGetNewPath =
    isNewFlowField or
    self.pathComplete or
    self.hasDeviatedPosition
  self:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)

  if shouldGetNewPath then
    self.pathComplete = false
    local distanceToPlanAhead = 5
    self.pathWithAstar = getPathWithAstar(flowField, grid, gridX, gridY, distanceToPlanAhead, self.WALKABLE, self.scale)

    local index = 1
    local path = self.pathWithAstar
    local pathLen = #path
    local posTween
    local done = true
    local isEmptyPath = pathLen == 0

    if isEmptyPath then
      return
    end

    self.positionTweener = function(dt)
      if index > pathLen then
        self.pathComplete = true
        return
      end

      if done then
        local pos = path[index]
        local nextPos = {
          x = pos.x * gridSize + centerOffset,
          y = pos.y * gridSize + centerOffset
        }
        local dist = distOfLine(self.x, self.y, nextPos.x, nextPos.y)
        local duration = dist / self.speed

        local easing = tween.easing.linear
        posTween = tween.new(duration, self, nextPos, easing)
        index = index + 1
      end
      done = posTween:update(dt)
    end
  end

  local originalX, originalY = self.x, self.y
  self.positionTweener(dt)
  local nextX, nextY = self.x, self.y

  local isMoving = originalX ~= nextX or originalY ~= nextY
  if not isMoving then
    return
  end

  local actualX, actualY, cols, len = self.collision:move(nextX, nextY, collisionFilter)
  local hasCollisions = len > 0

  self.hasDeviatedPosition = hasCollisions and
    (originalX ~= actualX or originalY ~= actualY)

  self.prevX = self.x
  self.prevY = self.y
  self.x = actualX
  self.y = actualY
  self.lastFlowField = flowField
end

function Ai:draw()
  -- agent color
  love.graphics.setColor(self.COLOR_FILL)

  local padding = 0
  love.graphics.rectangle(
    'fill',
    self.x + padding,
    self.y + padding,
    self.w - padding * 2,
    self.h - padding * 2
  )

  -- collision shape
  love.graphics.setColor(1,1,1,1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle(
    'line',
    self.collision.x + self.collision.ox,
    self.collision.y + self.collision.oy,
    self.collision.h,
    self.collision.w
  )
end

function Ai.create(x, y, speed, scale, collisionWorld, pxToGridUnits, WALKABLE, showAiPath)
  assert(WALKABLE ~= nil)
  assert(type(pxToGridUnits) == 'function')
  assert(collisionWorld ~= nil)

  if gridSize == nil then
    error('grid size must be defined. Call `Ai.setGridSize` to define it')
  end

  if scale % 1 == 0 then
    -- to prevent wall collision from getting stuck when pathing around corners, we'll adjust
    -- the agent size so its slightly smaller than the grid size.
    scale = scale - (2 / gridSize)
  end

  local scale = scale or 1
  local size = gridSize * scale
  --[[
    Padding is the difference between the full grid size and the actual rectangle size.
    Ie: if scale is 1.5, then the difference is (2 - 1.5) * gridSize
  ]]
  local padding = math.ceil(scale) * gridSize - size
  local w, h = size, size
  local colObj = collisionObject
    :new('ai', x, y, w, h)
    :addToWorld(collisionWorld)
  return setmetatable({
    x = x,
    y = y,
    w = w,
    h = h,
    id = uid(),
    -- used for centering the agent during movement
    padding = math.ceil(padding / 2),
    dx = 0,
    dy = 0,
    grid = grid,
    scale = scale,
    speed = speed or 100,
    collision = colObj,
    showAiPath = showAiPath,
    pxToGridUnits = pxToGridUnits,
    WALKABLE = WALKABLE,

    COLOR_FILL = {1,0,0,0.8}
  }, Ai_mt)
end

return Ai