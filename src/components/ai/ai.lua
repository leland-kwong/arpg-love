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
local noop = require 'utils.noop'
local Lru = require 'utils.lru'

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = animationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)

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

  -- calculated base properties (properties that can be changed from external modifiers)
  silenced = false,
  moveSpeed = 100,
  attackRange = 8,
  sightRadius = 11,
  armor = 0,
  maxHealth = 10,
  healthRegeneration = 0,
  damage = 0,

  isAggravated = false,
  gridSize = 1,
  fillColor = {1,1,1,1},
  facingDirectionX = 1,
  onInit = noop,
  onFinal = noop,
  onUpdateStart = nil,
  drawOrder = function(self)
    return self.group.drawOrder(self) + 1
  end
}

local popupText = PopupTextController.create({
  font = require 'components.font'.primary.font
})

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

local aggroMessageCache = Lru.new(100)

local function spreadAggroToAllies(self)
  local c = self.collision
  local areaMultiplier = 10
  local function aggravationCollisionFilter(item)
    return item.group == 'ai' and item ~= c
  end
  local items, len = self.collisionWorld:queryRect(
    c.x - c.ox * areaMultiplier,
    c.y - self.z - c.oy * areaMultiplier,
    c.w * areaMultiplier,
    c.h * areaMultiplier,
    aggravationCollisionFilter
  )

  for i=1, len do
    local ai = items[i].parent
    local canSee = self:checkLineOfSight(self.grid, Map.WALKABLE, ai:getProp('x'), ai:getProp('y'))
    if canSee and (not ai.isAggravated) then
      local id = ai:getId()
      local message = aggroMessageCache:get(id)
      if (not message) then
        message = {parent = ai}
        aggroMessageCache:set(id, message)
      end
      msgBus.send(msgBus.CHARACTER_AGGRO, message)
    end
  end
end

local function onDamageTaken(self, damage)
  self.health = self.health - damage
  local getTextSize = require 'components.gui.gui-text'.getTextSize
  local offsetCenter = -getTextSize(damage, popupText.font) / 2
  popupText:new(
    damage,
    self.x + offsetCenter,
    self.y - self.h
  )
  self.hitAnimation = coroutine.wrap(hitAnimation)

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
end

local function handleHits(self, dt)
  local hitManager = require 'modules.hit-manager'
  local hitCount = hitManager(self, dt, onDamageTaken)
  local hasHits = hitCount > 0

  local previouslyAggravated = self.isAggravated
  if hasHits then
    self.isAggravated = true
    if (not previouslyAggravated) then
      spreadAggroToAllies(self)
      -- put a short delay before setting `isAggravated` to false to prevent aggro spreading to cascade infinitely
      local tick = require 'utils.tick'
      tick.delay(function()
        self.isAggravated = false
      end, 0.5)
    end
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

function Ai._update2(self, grid, dt)
  if self.onUpdateStart then
    self.onUpdateStart(self, dt)
  end
  handleHits(self, dt)
  local playerRef = Component.get('PLAYER') or Component.get('TEST_PLAYER')
  local flowField = playerRef.flowField

  self.isFinishedMoving = true
  local playerRef = self.getPlayerRef and self.getPlayerRef() or Component.get('PLAYER')
  local playerX, playerY = playerRef:getPosition()
  local gridDistFromPlayer = Math.dist(self.x, self.y, playerX, playerY) / self.gridSize
  self.isInViewOfPlayer = gridDistFromPlayer <= 40
  self.gridDistFromPlayer = gridDistFromPlayer

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
      self:getCalculatedStat('sightRadius')
  local targetX, targetY = self.findNearestTarget(
    self.x,
    self.y,
    actualSightRadius
  )
  local canSeeTarget = self.isInViewOfPlayer and self:checkLineOfSight(grid, self.WALKABLE, targetX, targetY)
  local shouldGetNewPath = flowField and canSeeTarget
  local distFromTarget = canSeeTarget and distOfLine(self.x, self.y, targetX, targetY) or 99999
  local isInAttackRange = canSeeTarget and (distFromTarget <= self:getCalculatedStat('attackRange'))

  self:autoUnstuckFromWallIfNeeded(grid, gridX, gridY)

  self.canSeeTarget = canSeeTarget

  if canSeeTarget and (not self.silenced) then
    local Dash = require 'components.abilities.dash'
    if self:getCalculatedStat('attackRange') <= Dash.range then
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
    local flowFieldToUse = self.gridDistFromPlayer <= 6 and self.subFlowField or flowField
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
      local finishedMoving = index > #path
      if finishedMoving then
        self.pathWithAstar = nil
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
        local duration = dist / self:getCalculatedStat('moveSpeed')

        if duration <= 0 then
          done = true
          return
        end

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

  local actualX, actualY, cols, len = self.collision:move(nextX, nextY - self.z, collisionFilter)
  local hasCollisions = len > 0

  self.isFinishedMoving = (not canSeeTarget)
    or (canSeeTarget and isInAttackRange)

  self.hasDeviatedPosition = hasCollisions and
    (originalX ~= actualX or originalY ~= actualY)

  self.prevX = self.x
  self.prevY = self.y
  self.x = actualX
  self.y = actualY + self.z
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
  local heightScaleDiff = self.z * 0.01
  love.graphics.setColor(0,0,0,0.4)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y + (h * self.scale / 1.75),
    0,
    self.scale*0.8 * self.facingDirectionX - heightScaleDiff,
    -self.scale/2 + heightScaleDiff,
    ox,
    oy
  )
end

local function getStatusIcons()
  local iconAnimations = {}
  for spriteName,_ in pairs(animationFactory.frameData) do
    if string.find(spriteName, '^status-') then
      local animation = animationFactory:new({ spriteName })
      iconAnimations[spriteName] = animation
    end
  end
  return iconAnimations
end
local statusIconAnimations = getStatusIcons()
local function drawStatusEffects(self, statusIcons)
  local offsetX = 0
  local iconSize = 20
  for hitId,hit in pairs(self.hits) do
    if hit.statusIcon then
      love.graphics.draw(
        animationFactory.atlas,
        statusIconAnimations[hit.statusIcon].sprite,
        self.x + offsetX,
        self.y - 20 - self.z
      )
      offsetX = offsetX + iconSize
    end
  end
end

function Ai.draw(self)
  if (not self.isInViewOfPlayer) then
    return
  end

  local oBlendMode = love.graphics.getBlendMode()
  local ox, oy = self.animation:getOffset()
  local w, h = self.animation:getSourceSize()
  drawShadow(self, h, w, ox, oy)

  if (self.outlineColor) then
    love.graphics.setShader(shader)
    shader:send('outline_color', self.outlineColor)
    shader:send('fill_color', self.fillColor)
  end

  if self.hitAnimation then
    love.graphics.setBlendMode('add')
    love.graphics.setColor(3,3,3)
  end

  love.graphics.setColor(self.fillColor)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y - self.z,
    0,
    self.scale * self.facingDirectionX,
    self.scale,
    ox,
    oy
  )

  love.graphics.setColor(1,1,1)
  drawStatusEffects(self, statusIcons)

  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setShader()
  -- self:debugLineOfSight()
end

local function adjustInitialPositionIfNeeded(self)
  -- check initial position and move if necessary
  local actualX, actualY = self.collision:move(self.collision.x, self.collision.y - self.z, collisionFilter)
  self.x = actualX
  self.y = actualY
end

function Ai.init(self)
  assert(self.WALKABLE ~= nil)
  assert(type(self.pxToGridUnits) == 'function')
  assert(self.collisionWorld ~= nil)
  assert(type(self.grid) == 'table')
  assert(type(self.gridSize) == 'number')
  local scale = self.scale
  local gridSize = self.gridSize

  -- [[ BASE PROPERTIES ]]
  self.health = self.health or self.maxHealth

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
      self.y - self.z,
      self.w * self.scale,
      self.h * self.scale,
      ox * self.scale,
      oy * self.scale
    )
    :addToWorld(self.collisionWorld)
  adjustInitialPositionIfNeeded(self)

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
      local uid = require 'utils.uid'
      local hitId = msgValue.source or uid()
      self.hits[hitId] = msgValue
    end
  end)

  self.onInit(self)
end

function Ai.final(self)
  self.onFinal(self)
end

return Component.createFactory(Ai)