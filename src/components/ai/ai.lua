local Component = require 'modules.component'
local groups = require 'components.groups'
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
local Math = require 'utils.math'
local Enum = require 'utils.enum'
local Color = require 'modules.color'
local Map = require 'modules.map-generator.index'
local Position = require 'utils.position'

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = animationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})

local DirectionalFlowFields = require 'modules.flow-field.directional-flow-fields'
local subFlowFields = DirectionalFlowFields(function()
  local playerX, playerY = (Component.get('PLAYER') or Component.get('TEST_PLAYER')):getPosition()
  local config = require 'config.config'
  return Position.pixelsToGridUnits(playerX, playerY, config.gridSize)
end, Map.WALKABLE)
local getSubFlowField = (function()
  local index = 1
  return function()
    index = index + 1
    if index > #subFlowFields then
      index = 1
    end
    return subFlowFields[index]
  end
end)()

local Ai = {
  group = groups.all,
  health = 10,
  pulseTime = 0,
  silenced = false,
  speed = 100,
  attackRange = 8,
  sightRadius = 11,
  isAggravated = false,
  gridSize = 1,
  COLOR_FILL = {1,1,1,1},
  facingDirectionX = 1,
  drawOrder = function(self)
    return self.group.drawOrder(self) + 1
  end
}

local popupText = PopupTextController.create()

-- gets directions from grid position, adjusting vectors to handle wall collisions as needed
local aiPathWithAstar = require'modules.flow-field.pathing-with-astar'

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

function Ai:aggravatedRadius()
  local playerFlowFieldDistance = Component.get('PLAYER')
    :getProp('flowFieldDistance')
  return (playerFlowFieldDistance - 3) * self.gridSize
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
local collisionFilters = {
  player = true,
  ai = true,
  obstacle = true
}
local function collisionFilter(item, other)
  if collisionFilters[other.group] then
    return COLLISION_SLIDE
  end
  return false
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
  self.isAggravated = false
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
        msgBus.send(msgBus.ENEMY_DESTROYED, {
          x = self.x,
          y = self.y,
          experience = 1
        })
        self:delete()
        return
      end

      self.hits[i] = nil
    end

    self.hitAnimation = coroutine.wrap(hitAnimation)
    self.isAggravated = true
  end
end

local abilityDash = (function()
  local curCooldown = 0
  local skill = {}

  function skill.use(self)
    if curCooldown > 0 then
      return skill
    else
      local Dash = require 'components.abilities.dash'
      local projectile = Dash.create({
          fromCaster = self
        , cooldown = 1
        , duration = 7/60
        , range = require 'config.config'.gridSize * 6
      })
      curCooldown = projectile.cooldown
      return skill
    end
  end

  function skill.updateCooldown(self, dt)
    curCooldown = curCooldown - dt
    return skill
  end

  return skill
end)()

function Ai._update2(self, grid, flowField, dt)
  self.isFinishedMoving = true
  local playerRef = self.getPlayerRef and self.getPlayerRef() or Component.get('PLAYER')
  local playerX, playerY = playerRef:getPosition()
  local gridDistFromPlayer = Math.dist(self.x, self.y, playerX, playerY) / self.gridSize
  self.isInViewOfPlayer = gridDistFromPlayer <= 40
  self.gridDistFromPlayer = gridDistFromPlayer

  if self.pulseTime >= 0.4 then
    self.pulseDirection = -1
  elseif self.pulseTime <= 0 then
    self.pulseDirection = 1
  end
  self.pulseTime = self.pulseTime + dt * self.pulseDirection

  handleHits(self)

  if self:isDeleted() then
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
  local actualSightRadius = self.isAggravated and
      self:aggravatedRadius() or
      self.sightRadius
  local targetX, targetY = self.findNearestTarget(
    self.x,
    self.y,
    actualSightRadius
  )
  local canSeeTarget = self.isInViewOfPlayer and self:checkLineOfSight(grid, self.WALKABLE, targetX, targetY)
  local shouldGetNewPath = flowField and canSeeTarget
  local distFromTarget = canSeeTarget and distOfLine(self.x, self.y, targetX, targetY) or 99999
  local isInAttackRange = canSeeTarget and (distFromTarget <= self.attackRange)

  self:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)

  self.canSeeTarget = canSeeTarget

  if canSeeTarget and (not self.silenced) then
    local Dash = require 'components.abilities.dash'
    if self.attackRange <= Dash.range then
      if (distFromTarget <= Dash.range) then
        abilityDash.use(self)
        abilityDash.updateCooldown(self, dt)
      end
    end

    if isInAttackRange then
      self.ability1.use(self, targetX, targetY)
      self.ability1.updateCooldown(self, dt)
      -- we're already in attack range, so we don't need to move
      return
    end
  end

  if shouldGetNewPath then
    local distanceToPlanAhead = actualSightRadius / self.gridSize
    local flowFieldToUse = self.gridDistFromPlayer <= 8 and self.subFlowField or flowField
    self.pathWithAstar = self.getPathWithAstar(flowFieldToUse, grid, gridX, gridY, distanceToPlanAhead, self.WALKABLE, self.scale)

    local index = 1
    local path = self.pathWithAstar
    local posTween
    local done = true
    local isEmptyPath = #path == 0

    if isEmptyPath then
      return
    end

    self.positionTweener = function(dt)
      if index > #path then
        -- self.pathWithAstar = nil
        return
      end

      if done then
        local pos = path[index]
        local nextPos = {
          x = pos.x * self.gridSize,
          y = pos.y * self.gridSize
        }
        self.nextPos = nextPos

        local flowFieldValue = flowField[pos.y] and flowField[pos.y][pos.x]
        if flowFieldValue then
          self.direction.x = flowFieldValue.x
          self.direction.y = flowFieldValue.y
        else
          self.direction.x = 0
          self.direction.y = 0
        end

        local dist = distOfLine(self.x, self.y, nextPos.x, nextPos.y)
        local duration = dist / self.speed

        local easing = tween.easing.linear
        posTween = tween.new(duration, self, nextPos, easing)
        index = index + 1
      end
      done = posTween:update(dt)
    end
  end

  if self.isInViewOfPlayer then
    self.animation:update(dt / 12)
  end

  if not self.positionTweener then
    return
  end

  local originalX, originalY = self.x, self.y
  self.positionTweener(dt)
  local nextX, nextY = self.x, self.y

  local isMoving = originalX ~= nextX or originalY ~= nextY
  self.animation = isMoving and self.animations.moving or self.animations.idle
  if not isMoving then
    return
  end

  local actualX, actualY, cols, len = self.collision:move(nextX, nextY, collisionFilter)
  local hasCollisions = len > 0

  self.isFinishedMoving = (not canSeeTarget)
    or (canSeeTarget and isInAttackRange)

  self.hasDeviatedPosition = hasCollisions and
    (originalX ~= actualX or originalY ~= actualY)

  self.prevX = self.x
  self.prevY = self.y
  self.x = actualX
  self.y = actualY
  self.facingDirectionX = (originalX - self.x) > 0 and -1 or 1
  self.lastFlowField = flowField
end

local perf = require'utils.perf'
Ai._update2 = perf({
  enabled = false,
  done = function(_, totalTime, callCount)
    local avgTime = totalTime / callCount
    if (callCount % 100) == 0 then
      consoleLog('ai update -', avgTime)
    end
  end
})(Ai._update2)

local function drawShadow(self, h, w, ox, oy)
  love.graphics.setColor(0,0,0,0.4)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y + (h * self.scale / 1.75),
    0,
    self.scale * self.facingDirectionX,
    -self.scale/2,
    ox,
    oy
  )
end

function Ai.draw(self)
  if (not self.isInViewOfPlayer) then
    return
  end

  local ox, oy = self.animation:getOffset()
  local w, h = self.animation:getSourceSize()
  drawShadow(self, h, w, ox, oy)

  if self.hitAnimation then
    love.graphics.setShader(shader)
    shader:send('fill_color', Color.WHITE)
  else
    love.graphics.setColor(self.COLOR_FILL)
  end
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    0,
    self.scale * self.facingDirectionX,
    self.scale,
    ox,
    oy
  )

  love.graphics.setShader()

  -- self:debugLineOfSight()
end

function Ai.init(self)
  assert(self.WALKABLE ~= nil)
  assert(type(self.pxToGridUnits) == 'function')
  assert(self.collisionWorld ~= nil)
  assert(type(self.grid) == 'table')
  assert(type(self.gridSize) == 'number')
  local scale = self.scale
  local gridSize = self.gridSize
  self.hits = {}
  self.direction = {
    x = 0,
    y = 0
  }
  self.subFlowField = getSubFlowField()
  self.animation = self.animations.idle:update(math.random(0, 20) * 1/60)

  if scale % 1 == 0 then
    -- to prevent wall collision from getting stuck when pathing around corners, we'll adjust
    -- the agent size so its slightly smaller than the grid size.
    scale = scale - (2 / gridSize)
  end

  local scale = scale or 1
  local size = gridSize * scale
  if self.scale % 1 == 0 then
    self.scale = self.scale - 0.1
  end

  local ox, oy = self.animation:getOffset()
  self.collision = self:addCollisionObject(
      'ai',
      self.x,
      self.y,
      self.w * self.scale,
      self.h * self.scale,
      ox * self.scale,
      oy * self.scale
    )
    :addToWorld(self.collisionWorld)

  self.attackRange = self.attackRange * self.gridSize
  self.sightRadius = self.sightRadius * self.gridSize
  self.getPathWithAstar = Perf({
    enabled = false,
    done = function(t)
      consoleLog('ai path:', t)
    end
  })(aiPathWithAstar())

  msgBus.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgBus.CHARACTER_HIT == msgType and msgValue.parent == self then
      table.insert(self.hits, msgValue)
    end
  end)
end

return Component.createFactory(Ai)