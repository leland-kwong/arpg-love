local Component = require 'modules.component'
local groups = require 'components.groups'
local animationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
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
local setElectricShockShader = require 'modules.shaders.shader-electric-shock'
local Enum = require 'utils.enum'
local collisionGroups = require 'modules.collision-groups'
local Console = require 'modules.console.console'
local max, random, abs, min = math.max, math.random, math.abs, math.min

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = animationFactory.atlasData
local shaderSpriteSize = {atlasData.meta.size.w, atlasData.meta.size.h}

local states = Enum({
  'ATTACKING', -- attack has been triggered and character and character is still recovering from it
  'IDLE',
  'MOVING',
  'FREE_MOVING'
})

local Ai = {
  class = collisionGroups.ai,

  baseProps = {}, -- initial properties used to create the ai

  state = states.IDLE,
  attackRecoveryTime = 0,

  -- calculated base properties (properties that can be changed from external modifiers)
  silenced = false,
  moveSpeed = 100,
  attackRange = 8, -- distance in grid units from the player that the ai will stop moving
  sightRadius = 11,
  lightRadius = 100,
  armor = 0,
  flatPhysicalReduction = 0,
  lightningResist = 0,
  maxHealth = 10,
  healthRegeneration = 0,
  damage = 0,

  experience = 1, -- amount of experience the ai grants when destroyed

  frameCount = 0,
  clock = 0, -- amount of time the ai has been alive

  abilities = {},
  dataSheet = {
    name = '',
    properties = {}
  },

  vx = 0,
  vy = 0,

  -- elemental status effects
  shocked = 0,
  burning = 0,
  cold = 0,

  isAggravated = false,
  gridSize = 1,
  fillColor = {1,1,1,1},
  opacity = 1,
  facingDirectionX = 1,
  onInit = noop,
  onFinal = noop,
  onDestroyStart = noop,
  onUpdateStart = nil,

  drawOrder = function(self)
    return Component.groups.all:drawOrder(self) + 1
  end
}

-- gets directions from grid position, adjusting vectors to handle wall collisions as needed
local aiPathWithAstar = require'modules.flow-field.pathing-with-astar'

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

local COLLISION_SLIDE = 'slide'
local collisionFilters = collisionGroups.create(
  'player',
  'ai',
  'obstacle'
)
local function collisionFilter(item, other)
  if collisionGroups.matches(other.group, collisionFilters) then
    return COLLISION_SLIDE
  end
  return false
end

local aggroMessageCache = Lru.new(200)

local function spreadAggroToAllies(self)
  local c = self.collision
  local areaMultiplier = 10
  local function aggravationCollisionFilter(item)
    return collisionGroups.matches(item.group, collisionGroups.ai) and (item ~= c)
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
    local canSee = self:checkLineOfSight(self.grid, Map.WALKABLE, ai.x, ai.y)
    if canSee and (not ai.isAggravated) then
      local id = ai:getId()
      local message = aggroMessageCache:get(id)
      if (not message) then
        message = {parent = ai}
        aggroMessageCache:set(id, message)
      end
      -- trigger a hit message with no damage
      msgBus.send(msgBus.CHARACTER_HIT, message)
    end
  end
end

local function handleAggro(self, dt)
  local previouslyAggravated = self.isAggravated
  local hasHits = self.hitCount > 0
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
		local dist = max(0.01, Math.dist(self.x, self.y, n.x, n.y) - n.w*0.5 - self.w*0.5)
		sx = sx + (sepX/dist)
		sy = sy + (sepY/dist)
	end

	-- Note that this isn't normalised as you want the influence to reduce if the entity is well separated.
	-- You could apply a similar approach to other influence vectors depending on what sort of behaviour you want
	return sx, sy
end

local function obstacleFilter(item)
  return collisionGroups.matches(item.group, collisionGroups.obstacle)
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
  dist = max(0.01, dist - self.w*0.5)
	local sepX, sepY = Math.normalizeVector(self.x - no.x, self.y - no.y)

	return sepX/dist, sepY/dist
end

local function neighborFilter(item)
  return collisionGroups.matches(item.group, 'ai')
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

local function setNextPosition(self, speed, radius)
  local finiteState = self:getFiniteState()
  if (finiteState ~= states.MOVING) and (finiteState ~= states.FREE_MOVING) then
    return
  end

  local neighbors = getNeighbors(self, 10)

	-- These calcs are to get an adjustment for movement speed based on distance.
	-- Don't take this as a complete solution as it only works based on the mouse target for
	-- this test setup.
	-- In reality you need to be a bit smarter about slowing/stopping AI entities when
	-- they have reached a goal point. This will often tie into the combat system (stopping
  -- when they can hit the player, for example).
  local targetX, targetY = self.targetX, self.targetY
	local targetDist = Math.dist(self.x, self.y, targetX, targetY)
	local targetDistDamping = min(1.0, targetDist/radius)

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

  local Vec2 = require 'modules.brinevector'
  self.prevX, self.prevY = self.prevX or 0, self.prevY or 0
  self.dv = self.dv or Vec2(0, 0)
  self.dv.x, self.dv.y = self.x - self.prevX, self.y - self.prevY
  self.prevX, self.prevY = self.x, self.y
end

function Ai.getFiniteState(self)
  if self.modifiers.freelyMove > 0 then
    return states.FREE_MOVING
  end

  if self.attackRecoveryTime > 0 then
    return states.ATTACKING
  end

  if self.targetX ~= nil then
    return states.MOVING
  end

  return states.IDLE
end

function Ai.getActualSpeed(self, dt)
  return max(0, self:getCalculatedStat('moveSpeed') * dt)
end

local function createLight(self)
  if self.lightRadius then
    local Lights = require 'components.lights'
    self.light = self.light or Lights.create({
      x = self.x,
      y = self.y,
      radius = self.lightRadius,
      lightWorld = 'DUNGEON_LIGHT_WORLD'
    }):setParent(self)
  end
end

function Ai.update(self, dt)
  handleAggro(self, dt)
  local isIdle = (self:getFiniteState() ~= states.MOVING) and (not self.isInViewOfPlayer) and (not self.isAggravated)
  self:setDrawDisabled(isIdle)
  if isIdle then
    if self.light then
      self.light:delete()
      self.light = nil
    end
    return
  end

  local shouldCheckStuckStatus = self:getFiniteState() == states.MOVING and self.dv and (not self.canSeeTarget)
  if shouldCheckStuckStatus then
    if self.isInAttackRange then
      self.checkCount = 0
    end

    self.checkCount = (self.checkCount or 0) + 1
    if self.checkCount >= 60 then
      local isStuck = abs(self.dv.x) <= 6 and abs(self.dv.y) <= 6
      if isStuck then
        self.targetX = nil
      end
      self.checkCount = 0
      self.dv = self.dv * 0
    end
  end

  createLight(self)

  local playerRef = Component.get('PLAYER') or Component.get('TEST_PLAYER')
  local playerX, playerY = playerRef:getPosition()

  local grid = self.grid
  self.clock = self.clock + dt
  self.frameCount = self.frameCount + 1
  self.attackRecoveryTime = self.attackRecoveryTime - dt

  if self.destroyedAnimation then
    return
  end

  if self.onUpdateStart then
    self.onUpdateStart(self, dt)
  end

  local targetX, targetY

  if (self.isInViewOfPlayer or self.isAggravated) then
    -- update ai facing direction
    if (self.frameCount % 5 == 0) then
      local shouldFlipX = abs(self.vx) > 0.15
      self.facingDirectionX = shouldFlipX and (self.vx > 0 and 1 or -1) or self.facingDirectionX
      self.facingDirectionY = self.vy > 0 and 1 or -1
    end

    -- handle hit animation
    if self.hitAnimation then
      local done = self.hitAnimation()
      if done then
        self.hitAnimation = nil
      end
    end

    targetX, targetY = self.findNearestTarget(
      self.x,
      self.y,
      40 * self.gridSize
    )

    self.animation:update(dt / 12)
  end

  local actualSightRadius = self:getCalculatedStat('sightRadius')
  local canSeeTarget = self.isInViewOfPlayer and self:checkLineOfSight(grid, self.WALKABLE, targetX, targetY, self.losDebug)
  local gridDistFromPlayer = Math.dist(self.x, self.y, playerX, playerY) / self.gridSize
  local isInAggroRange = gridDistFromPlayer <= (actualSightRadius / self.gridSize)
  local distFromTarget = canSeeTarget and distOfLine(self.x, self.y, targetX, targetY) or 99999
  local isInAttackRange = canSeeTarget and (distFromTarget <= self:getCalculatedStat('attackRange'))
  local originalX, originalY = self.x, self.y

  self.canSeeTarget = canSeeTarget

  if canSeeTarget and (isInAggroRange or self.isAggravated) then
    local path
    local gridX, gridY = self.pxToGridUnits(self.x, self.y, self.gridSize)
    self.targetX, self.targetY = targetX, targetY

    -- use abilities
    if (not self.silenced) then
      local abilities = self.abilities
      for i=1, #abilities do
        local ability = abilities[i]
        -- local isInAbilityRange = distFromTarget <= ability.range * self.gridSize
        local isRecoveringFromAttack = self.attackRecoveryTime > 0
        local finiteState = self:getFiniteState()
        local canUseAbility = (not isRecoveringFromAttack)
          and (finiteState == states.MOVING)
        ability:update(self, dt)
        if canUseAbility then
          -- execute ability and get new attack recovery time
          local recoveryTime = ability:use(self, targetX, targetY, distFromTarget)
          self.attackRecoveryTime = recoveryTime
        end
      end
    end

    self.isInAttackRange = isInAttackRange
    local isTargetStillAtLastKnownPosition = self.targetX == targetX and self.targetY == targetY
    if isInAttackRange and isTargetStillAtLastKnownPosition then
      -- we're already in attack range, so we can stop the update here since the rest of the update is just moving
      return
    end
  end
  if self.targetX and (self:getFiniteState() ~= states.ATTACKING) then
    setNextPosition(self, self:getActualSpeed(dt), 40)
  end

  local nextX, nextY = self.x, self.y

  local isMoving = originalX ~= nextX or originalY ~= nextY
  self.animation = isMoving and self.animations.moving or self.animations.idle
end

local perf = require'utils.perf'
Ai.update = perf({
  enabled = false,
  beforeCall = function()
    Console.jprof.push('ai_update')
  end,
  done = function(time, totalTime, callCount)
    Console.jprof.pop('ai_update')
  end
})(Ai.update)

local function drawShadow(self, h, w, ox, oy)
  local heightScaleDiff = self.z * 0.01
  love.graphics.setColor(0,0,0,0.3 * self.opacity)
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
  for hitId,hit in pairs(self.hitData) do
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

function drawSprite(self, ox, oy)
  local atlas = animationFactory.atlas
  love.graphics.draw(
    atlas,
    self.animation.sprite,
    self.x,
    self.y - self.z,
    0,
    self.scale * self.facingDirectionX,
    self.scale,
    ox,
    oy
  )
end

local textureW, textureH = animationFactory.atlas:getDimensions()
local shockResMult = 10
local shockResolution = textureH > textureW
  and {
    (textureW/textureH) * shockResMult,
    1 * shockResMult,
  }
  or {
    1 * shockResMult,
    (textureH/textureW) * shockResMult,
  }

local function drawShockEffect(self, ox, oy)
  setElectricShockShader(
    math.pow(math.sin(self.clock + self.clockOffset), 2),
    shockResolution
  )
  love.graphics.setColor(0.8,0.8,1,self.opacity)
  drawSprite(self, ox, oy)
end

local function debugLineOfSight(self)
  if self.losPoints then
    for i=1, #self.losPoints do
      local pt = self.losPoints[i]
      if pt.isBlocked then
        love.graphics.setColor(1,0,0)
      else
        love.graphics.setColor(1,1,1)
      end
      love.graphics.rectangle('line', pt.x, pt.y, self.gridSize, self.gridSize)
    end
  end
end

function Ai.draw(self)
  debugLineOfSight(self)

  local oBlendMode = love.graphics.getBlendMode()
  local ox, oy = self.animation:getOffset()
  local w, h = self.animation:getSourceSize()
  drawShadow(self, h, w, ox, oy)

  if (self.outlineColor) then
    love.graphics.setShader(shader)
    shader:send('sprite_size', shaderSpriteSize)
    shader:send('outline_width', 1)
    shader:send('outline_color', self.outlineColor)
    shader:send('fill_color', self.fillColor)
    shader:send('alpha', self.opacity)
  end

  if self.hitAnimation and (not self.destroyedAnimation) then
    love.graphics.setBlendMode('add')
    love.graphics.setColor(3,3,3)
  end

  local texture = animationFactory.atlas
  local r,g,b,a = self.fillColor[1], self.fillColor[2], self.fillColor[3], self.fillColor[4]
  love.graphics.setColor(r, g, b, a * self.opacity)
  drawSprite(self, ox, oy)

  local isShocked = self:getCalculatedStat('shocked') > 0
  if (isShocked) then
    drawShockEffect(self, ox, oy)
  end

  love.graphics.setBlendMode(oBlendMode)
  love.graphics.setShader()

  love.graphics.setColor(1,1,1, self.opacity)
  drawStatusEffects(self, statusIcons)
end

local function adjustInitialPositionIfNeeded(self)
  -- check initial position and move if necessary
  local actualX, actualY = self.collision:move(self.collision.x, self.collision.y, collisionFilter)
  self.x = actualX
  self.y = actualY
end

local function setupAbilities(self)
  local abilityManager = require 'modules.abilities.manager'
  for i=1, #self.abilities do
    -- transform ability into a coroutine
    self.abilities[i] = abilityManager.new(self.abilities[i])
  end
end

function Ai.init(self)
  assert(self.WALKABLE ~= nil)
  assert(type(self.pxToGridUnits) == 'function')
  assert(self.collisionWorld ~= nil)
  assert(type(self.grid) == 'table')
  assert(type(self.gridSize) == 'number')
  local scale = self.scale
  local gridSize = self.gridSize

  Component.addToGroup(self, groups.all)
  Component.addToGroup(self, groups.character)
  Component.addToGroup(self, 'disabled')
  self.onDamageTaken = require 'modules.handle-damage-taken'

  -- [[ BASE PROPERTIES ]]
  self.health = self.health or self.maxHealth
  self.clockOffset = math.random(0, 100)

  if self.debug then
    self.losDebug = function(x, y, isBlocked)
      local isNewFrame = self.lastFrameCount ~= self.frameCount
      if isNewFrame then
        self.losPoints = {}
        self.lastFrameCount = self.frameCount
      end
      table.insert(
        self.losPoints, {
          x = x * self.gridSize,
          y = y * self.gridSize,
          isBlocked = isBlocked
        }
      )
    end
  end

  self.direction = {
    x = 0,
    y = 0
  }
  -- start idle animation at a random point to add variance to the ai's idle state
  self.animation = self.animations.idle:update(math.random(0, 20) * 1/60)

  setupAbilities(self)

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
      collisionGroups.ai,
      self.x,
      self.y,
      self.w * self.scale,
      self.h * self.scale,
      ox * self.scale,
      oy + self.z * self.scale
    )
    :addToWorld(self.collisionWorld)
  adjustInitialPositionIfNeeded(self)

  self.attackRange = self.attackRange * self.gridSize
  self.sightRadius = self.sightRadius * self.gridSize
  self.getPathWithAstar = Perf({
    enabled = false,
    done = function(_, totalTime, callCount)
      consoleLog('ai path:', totalTime/callCount)
    end
  })(aiPathWithAstar())

  self.onInit(self)
end

function Ai.serialize(self)
  local objectUtils = require 'utils.object-utils'
  local propsToSave = {'health', 'x', 'y'}
  for i=1, #propsToSave do
    local prop = propsToSave[i]
    local val = self[prop]
    self.initialProps:set(prop, val)
  end
  return self.initialProps
end

return Component.createFactory(Ai)