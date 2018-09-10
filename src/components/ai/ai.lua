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
  flatPhysicalDamageReduction = 0,
  maxHealth = 10,
  healthRegeneration = 0,
  damage = 0,
  frameCount = 0,

  abilities = {},
  dataSheet = {
    name = '',
    properties = {}
  },

  vx = 0,
  vy = 0,

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

local aggroMessageCache = Lru.new(200)

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

local max = math.max
local round = require 'utils.math'.round
local damageReductionPerArmor = 0.0001
local function adjustedDamage(self, damage)
  local damageAfterFlatReduction = damage - self.flatPhysicalDamageReduction
  local finalDamage = damageAfterFlatReduction -
    (damageAfterFlatReduction * self.armor * damageReductionPerArmor)
  return round(
    max(0, finalDamage)
  )
end

local function onDamageTaken(self, damage)
  local actualDamage = adjustedDamage(self, damage)
  self.health = self.health - actualDamage
  local getTextSize = require 'components.gui.gui-text'.getTextSize
  local offsetCenter = -getTextSize(actualDamage, popupText.font) / 2
  popupText:new(
    actualDamage,
    self.x + offsetCenter,
    self.y - self.h
  )
  self.hitAnimation = coroutine.wrap(hitAnimation)

  local Sound = require 'components.sound'
  Sound.ENEMY_IMPACT:setFilter {
    type = 'lowpass',
    volume = .5,
  }
  love.audio.stop(Sound.ENEMY_IMPACT)
  love.audio.play(Sound.ENEMY_IMPACT)

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
      end, 1)
    end
  end
end

local function computeAlignment(self, neighbors)
	local vx, vy = 0, 0
	local neighborCount = #neighbors
  for i=1, neighborCount do
    local n = neighbors[i].parent
		vx = vx + n.vx
		vy = vy + n.vy
	end
	if neighborCount > 0 then
		vx = vx / neighborCount
		vy = vy / neighborCount
	end
	return Math.normalizeVector(vx, vy)
end

local function computeCohesion(self, neighbors)
	local px, py = 0, 0
	local neighborCount = #neighbors
	for i=1, neighborCount do
    local n = neighbors[i].parent
    if (not n.isInAttackRange) then
      px = px + n.x
      py = py + n.y
    end
	end
	if neighborCount > 0 then
		px = px / neighborCount
		py = py / neighborCount
	end
	px = px - self.x
	py = py - self.y
	return Math.normalizeVector(px, py)
end

local function computeSeparation(self, neighbors)
	local sx, sy = 0, 0
	local neighborCount = #neighbors
	for i=1, neighborCount do
		local n = neighbors[i].parent
		-- add separation vector, reducing strength by distance
		-- this can be fancier with decay by the square or taking into account weight or whatever
		local sepX, sepY = Math.normalizeVector(self.x - n.x, self.y - n.y)
		local dist = math.max(0.01, Math.dist(self.x, self.y, n.x, n.y) - n.w*0.5 - self.w*0.5)
		sx = sx + (sepX/dist)
		sy = sy + (sepY/dist)
	end

	-- Note that this isn't normalised as you want the influence to reduce if the entity is well separated.
	-- You could apply a similar approach to other influence vectors depending on what sort of behaviour you want
	return sx, sy
end

local function obstacleFilter(item)
  return item.group == 'obstacle'
end

local function computeObstacleInfluence(self)
  local obstacles, len = self.collision.world:queryRect(
    self.x - self.w,
    self.y - self.h,
    self.w * 3,
    self.h * 3,
    obstacleFilter
  )
  local dist = 99999
  local no = nil
  for i=1, len do
    local o = obstacles[i]
    local curDist = Math.dist(self.x, self.y, o.x + o.w/2, o.y + o.h/2) - (o.w * 0.5)
    if curDist < dist then
      no = o
      dist = curDist
    end
  end
  if (len == 0) then
    return 0, 0
  end
	-- We'll just use the single nearest obstacle.
	-- A lot of the time this is enough but more complex environments might need influences from all nearby obstacles
  dist = math.max(0.01, dist - self.w*0.5)
	local sepX, sepY = Math.normalizeVector(self.x - no.x, self.y - no.y)

	return sepX/dist, sepY/dist
end

local function neighborFilter(item)
  return item.group == 'ai'
end
local function getNeighbors(agent, neighborOffset)
	local b = agent
	return agent.collision.world:queryRect(
		b.x - neighborOffset/2,
		b.y - neighborOffset/2,
		b.w + neighborOffset,
    b.h + neighborOffset,
    neighborFilter
	)
end

local function setNextPosition(self, dt, radius)
  local neighbors = getNeighbors(self, 10)
  local speed = self.moveSpeed * dt

	-- These calcs are to get an adjustment for movement speed based on distance.
	-- Don't take this as a complete solution as it only works based on the mouse target for
	-- this test setup.
	-- In reality you need to be a bit smarter about slowing/stopping AI entities when
	-- they have reached a goal point. This will often tie into the combat system (stopping
  -- when they can hit the player, for example).
  local targetX, targetY = self.targetX, self.targetY
	local targetDist = Math.dist(self.x, self.y, targetX, targetY)
	local targetDistDamping = math.min(1.0, targetDist/radius)

	-- Calculate direction influence vectors
	-- Remember that you're not bound to the classical boids here. You can add influences from all sorts
	-- of things in your game. I've added some obstacles (which could be traps or fire or whatever) to demonstrate.
	local targetDirX, targetDirY = Position.getDirection(self.x, self.y, targetX, targetY)
	local alignmentX, alignmentY = computeAlignment(self, neighbors)
	local cohesionX, cohesionY = computeCohesion(self, neighbors)
	local separationX, separationY = computeSeparation(self, neighbors)
	local obstInfluenceX, obstInfluenceY = computeObstacleInfluence(self)

	-- these are the weights for each influence vector and can be adjusted to get different behaviours
	local separationWeight = 4
	local alignmentWeight = 0.1
	local cohesionWeight = 0.4
	local targetDirectionWeight = 1.5
	local obstInfluenceWeight = 6.0

	-- Now we calculate the overall influence vector
	local adjustedVx = targetDirX*targetDirectionWeight + obstInfluenceX*obstInfluenceWeight + (alignmentX * alignmentWeight) + (cohesionX * cohesionWeight) + (separationX * separationWeight)
	local adjustedVy = targetDirY*targetDirectionWeight + obstInfluenceY*obstInfluenceWeight + (alignmentY * alignmentWeight) + (cohesionY * cohesionWeight) + (separationY * separationWeight)

	-- Normalise to a direction vector
	local normVx, normVy = Math.normalizeVector(adjustedVx, adjustedVy)

	-- Here I'm effectively lerping the direction just to smooth things out a bit. Completely optional/adjustable
	self.vx = (self.vx + normVx) * 0.5
	self.vy = (self.vy + normVy) * 0.5

  -- Apply direction with speed and our damping based on the target distance
	self.x = self.x + self.vx * speed * targetDistDamping
  self.y = self.y + self.vy * speed * targetDistDamping
  self.collision:update(self.x, self.y)
end

function Ai._update2(self, grid, dt)
  self.frameCount = self.frameCount + 1

  if self.onUpdateStart then
    self.onUpdateStart(self, dt)
  end
  handleHits(self, dt)

  if (self.frameCount % 5 == 0) then
    local shouldFlipX = math.abs(self.vx) > 0.15
    self.facingDirectionX = shouldFlipX and (self.vx > 0 and 1 or -1) or self.facingDirectionX
    self.facingDirectionY = self.vy > 0 and 1 or -1
  end

  local playerRef = Component.get('PLAYER') or Component.get('TEST_PLAYER')
  local flowField = playerRef.flowField

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
  local originalX, originalY = self.x, self.y

  self.canSeeTarget = canSeeTarget

  if canSeeTarget then
    -- use abilities
    if (not self.silenced) then
      local abilities = self.abilities
      for i=1, #abilities do
        local ability = abilities[i]
        if (distFromTarget <= ability.range * self.gridSize) then
          ability.use(self, targetX, targetY)
          ability.updateCooldown(self, dt)
        end
      end
    end

    self.isInAttackRange = isInAttackRange
    if isInAttackRange then
      -- we're already in attack range, so we can stop the update here since the rest of the update is just moving
      return
    end

    if shouldGetNewPath then
      local distanceToPlanAhead = actualSightRadius / self.gridSize
      local path = self.getPathWithAstar(flowField, grid, gridX, gridY, distanceToPlanAhead, self.WALKABLE, self.scale)
      local targetPos = path[#path]
      self.targetX, self.targetY = targetPos.x * self.gridSize, targetPos.y * self.gridSize
      setNextPosition(self, dt, 40)
    end
  elseif self.targetX then
    setNextPosition(self, dt, 40)
  end

  if self.isInViewOfPlayer then
    self.animation:update(dt / 12)
  end

  local nextX, nextY = self.x, self.y

  local isMoving = originalX ~= nextX or originalY ~= nextY
  self.animation = isMoving and self.animations.moving or self.animations.idle
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
  love.graphics.setColor(0,0,0,0.3)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y + (h * self.scale / 1.3),
    0,
    self.scale*0.9 * self.facingDirectionX - heightScaleDiff,
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

  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setShader()

  love.graphics.setColor(1,1,1)
  drawStatusEffects(self, statusIcons)
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
  -- start idle animation at a random point to add variance to the ai's idle state
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