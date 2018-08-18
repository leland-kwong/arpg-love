local animationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local PopupTextController = require 'components.popup-text'
local getAdjacentWalkablePosition = require 'modules.get-adjacent-open-position'
local collisionObject = require 'modules.collision'
local uid = require'utils.uid'
local tween = require 'modules.tween'
local socket = require 'socket'
local distOfLine = require'utils.math'.dist
local memoize = require'utils.memoize'
local LineOfSight = memoize(require'modules.line-of-sight')
local Perf = require'utils.perf'
local dynamic = require'modules.dynamic-module'

local Ai = {}
local Ai_mt = {__index = Ai}

local popupText = PopupTextController.create()

-- gets directions from grid position, adjusting vectors to handle wall collisions as needed
local aiPathWithAstar = require'modules.flow-field.pathing-with-astar'
local getPathWithAstar = Perf({
  enabled = false,
  done = function(t)
    print('ai path:', t)
  end
})(aiPathWithAstar)

Ai.debugLineOfSight = dynamic('components/ai/line-of-sight.debug.lua')

function Ai:checkLineOfSight(grid, WALKABLE, targetX, targetY, debug)
  if not targetX then
    return false
  end

  local gridX, gridY = self.pxToGridUnits(self.x, self.y, self.gridSize)
  local gridTargetX, gridTargetY = self.pxToGridUnits(targetX, targetY, self.gridSize)
  return LineOfSight(grid, WALKABLE, debug)(
    gridX, gridY, gridTargetX, gridTargetY
  )
end

function Ai:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)
  local row = grid[gridY]
  local isInsideWall = (not row) or (row[gridX] ~= self.WALKABLE)

  if isInsideWall then
    local openX, openY = getAdjacentWalkablePosition(grid, gridX, gridY, self.WALKABLE)
    if openX then
      local nextX, nextY = openX * self.gridSize, openY * self.gridSize
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

local function hitAnimation()
  local frame = 0
  local animationLength = 4
  while frame < animationLength do
    frame = frame + 1
    coroutine.yield(false)
  end
  coroutine.yield(true)
end

local function handleHits(self)
  local hitCount = #self.hits
  if hitCount > 0 then
    for i=1, hitCount do
      local hit = self.hits[i]
      self.health = self.health - hit.damage

      local offsetCenter = 6
      popupText:new(
        hit.damage,
        self.x + (self.w / 2) - offsetCenter,
        self.y - self.h
      )

      local isDestroyed = self.health <= 0
      if isDestroyed then
        self:final()
        return
      end
    end

    self.hitAnimation = coroutine.wrap(hitAnimation)
    self.hits = {}
  end
end

function Ai:update(grid, flowField, dt)
  if self.pulseTime >= 0.4 then
    self.pulseDirection = -1
  elseif self.pulseTime <= 0 then
    self.pulseDirection = 1
  end
  self.pulseTime = self.pulseTime + dt * self.pulseDirection

  handleHits(self)

  if self.deleted then
    return
  end

  if self.hitAnimation then
    local done = self.hitAnimation()
    if done then
      self.hitAnimation = nil
    end
  end

  local centerOffset = self.padding
  local prevGridX, prevGridY = self.pxToGridUnits(self.prevX or 0, self.prevY or 0, self.gridSize)
  local gridX, gridY = self.pxToGridUnits(self.x, self.y, self.gridSize)
  -- we can use this detect whether the agent is stuck if the grid position has remained the same for several frames and was trying to move
  local isNewGridPosition = prevGridX ~= gridX or prevGridY ~= gridY
  local isNewFlowField = self.lastFlowField ~= flowField
  local targetX, targetY = self.findNearestTarget(self.x, self.y, self.sightRadius)
  local canSeeTarget = self:checkLineOfSight(grid, self.WALKABLE, targetX, targetY)
  local shouldGetNewPath = flowField and canSeeTarget
  self:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)

  self.canSeeTarget = canSeeTarget

  if shouldGetNewPath then
    self.pathComplete = false
    local distanceToPlanAhead = self.sightRadius / self.gridSize
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
          x = pos.x * self.gridSize + centerOffset,
          y = pos.y * self.gridSize + centerOffset
        }
        local dist = distOfLine(self.x, self.y, nextPos.x, nextPos.y)

        if dist == 0 then
          print(self.x, self.y, nextPos.x, nextPos.y)
        end

          local duration = dist / self.speed

        local easing = tween.easing.linear
        posTween = tween.new(duration, self, nextPos, easing)
        index = index + 1
      end
      done = posTween:update(dt)
    end
  end

  if not self.positionTweener then
    return
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

local function drawShadow(self)
  love.graphics.setColor(0,0,0,0.15)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x + 1,
    self.y + 10,
    0,
    self.w - 2,
    self.h,
    1,
    1
  )
end

function Ai:draw()
  local padding = 0
  local sizeIncreaseX, sizeIncreaseY = (self.w * self.pulseTime), (self.h * self.pulseTime)
  local drawWidth, drawHeight = self.w + sizeIncreaseX, self.h + sizeIncreaseY

  drawShadow(self)

  -- border
  local borderWidth = 2
  love.graphics.setColor(0,0,0)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    0,
    drawWidth,
    drawHeight,
    1,
    1
  )

  if self.hitAnimation then
    love.graphics.setColor(1,1,1,1)
  else
    love.graphics.setColor(self.COLOR_FILL)
  end
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x + borderWidth/2,
    self.y + borderWidth/2,
    0,
    drawWidth - borderWidth,
    drawHeight - borderWidth,
    1,
    1
  )

  -- self:debugLineOfSight()
end

function Ai:final()
  self.deleted = true
  self.collision:delete()
  msgBus.send(msgBus.GENERATE_LOOT, {self.x, self.y})
end

function Ai.create(x, y, speed, scale, collisionWorld, pxToGridUnits, findNearestTarget, grid, gridSize, WALKABLE, showAiPath)
  assert(WALKABLE ~= nil)
  assert(type(pxToGridUnits) == 'function')
  assert(collisionWorld ~= nil)
  assert(type(grid) == 'table')
  assert(type(gridSize) == 'number')

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

  local entity = setmetatable({
    x = x,
    y = y,
    w = w,
    h = h,
    health = 10,
    id = uid(),
    pulseTime = 0,
    hits = {},
    -- used for centering the agent during movement
    padding = math.ceil(padding / 2),
    dx = 0,
    dy = 0,
    scale = scale,
    speed = speed or 100,
    sightRadius = 10 * gridSize, -- pixel units
    collision = colObj,
    grid = grid,
    gridSize = gridSize,
    showAiPath = showAiPath,
    pxToGridUnits = pxToGridUnits,
    findNearestTarget = findNearestTarget,
    WALKABLE = WALKABLE,

    animation = animationFactory:new({
      'pixel-white-1x1'
    }),
    COLOR_FILL = {0,0.9,0.3,1}
  }, Ai_mt)

  local self = entity

  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.CHARACTER_HIT == msgType and msgValue.parent == self then
      table.insert(self.hits, msgValue)
    end
  end)

  colObj:setParent(self)

  return self
end

return Ai