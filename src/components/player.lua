local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local ParticleFx = require 'components.particle.particle'
local config = require 'config'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local camera = require 'components.camera'
local Position = require 'utils.position'
local Map = require 'modules.map-generator.index'
local Flowfield = require 'modules.flow-field.flow-field'
local Color = require 'modules.color'
local memoize = require 'utils.memoize'
local LineOfSight = memoize(require'modules.line-of-sight')
local getDist = memoize(require('utils.math').dist)

local colMap = collisionWorlds.map
local keyMap = config.keyboard
local mouseInputMap = config.mouseInputMap

local startPos = {
  x = config.gridSize * 3,
  y = config.gridSize * 3,
}

local frameRate = 60
local DIRECTION_RIGHT = 1
local DIRECTION_LEFT = -1

local collisionGroups = {
  obstacle = true,
  ai = true
}

local function collisionFilter(item, other)
  if not collisionGroups[other.group] then
    return false
  end
  return 'slide'
end

local Player = {
  group = groups.all,
  x = startPos.x,
  y = startPos.y,
  pickupRadius = 5 * config.gridSize,
  speed = 100,

  -- collision properties
  type = 'player',
  h = 1,
  w = 1,
  mapGrid = nil,

  init = function(self)
    local CreateStore = require'components.state.state'
    self.rootStore = self.rootStore or CreateStore()
    self.dir = DIRECTION_RIGHT
    colMap:add(self, self.x, self.y, self.w, self.h)

    self.animations = {
      idle = animationFactory:new({
        'character-1',
        'character-8',
        'character-9',
        'character-10',
        'character-11'
      }),
      run = animationFactory:new({
        'character-15',
        'character-16',
        'character-17',
        'character-18',
      })
    }

    local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
    self.outlineColor = {1,1,1,1}
    self.shader = love.graphics.newShader(pixelOutlineShader)
    local atlasData = animationFactory.atlasData
    self.shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
    self.shader:send('outline_width', 1)
    self.shader:send('outline_color', self.outlineColor)

    self.colObj = self:addCollisionObject(
      'player',
      self.x,
      self.y,
      self.w,
      self.h
    ):addToWorld(colMap)

    local gridRowsCols = memoize(function(grid)
      return #grid, #grid[1]
    end)
    local function isOutOfBounds(grid, x, y)
      local rows, cols = gridRowsCols(grid)
      return y < 1 or x < 1 or y > rows or x > cols
    end
    self.isGridCellVisitable = function(grid, x, y, dist)
      return not isOutOfBounds(grid, x, y) and
        grid[y][x] == Map.WALKABLE and
        dist < 20
    end

    local calcDist = require'utils.math'.dist
    msgBus.subscribe(function(msgType, msg)
      if self:isDeleted() then
        return msgBus.CLEANUP
      end

      if msgBus.PLAYER_DISABLE_ABILITIES == msgType then
        self.clickDisabled = msg
      end

      if msgBus.ITEM_PICKUP == msgType then
        local item = msg
        local dist = calcDist(self.x, self.y, item.x, item.y)
        local outOfRange = dist > self.pickupRadius
        local gridX1, gridY1 = Position.pixelsToGrid(self.x, self.y, config.gridSize)
        local gridX2, gridY2 = Position.pixelsToGrid(item.x, item.y, config.gridSize)
        local canWalkToItem = LineOfSight(self.mapGrid, Map.WALKABLE)(gridX1, gridY1, gridX2, gridY2)
        if outOfRange or (not canWalkToItem) then
          msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, true)
          -- move towards item
          self.forceMove = true
        elseif canWalkToItem then
          self.forceMove = false
          item:pickup()
        end
      elseif (msgBus.ITEM_PICKUP_CANCEL == msgType) or (msgBus.ITEM_PICKUP_SUCCESS == msgType) then
        self.forceMove = false
        msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, false)
      end

      if msgBus.ITEM_HOVERED == msgType then
        msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, msg)
      end

      if msgBus.DROP_ITEM_ON_FLOOR == msgType then
        local dropX, dropY = self.x + math.random(0, 16),
          self.y + math.random(0, 16)
        msgBus.send(
          msgBus.GENERATE_LOOT,
          {dropX, dropY, msg}
        )
      end

      if msgBus.PLAYER_LEVEL_UP == msgType then
        local tick = require 'utils.tick'
        local fx = ParticleFx.Basic.create({
          x = self.x,
          y = self.y + 10,
          duration = 1,
          width = 4
        }):setParent(self)
      end

      if msgBus.CHARACTER_HIT == msgType and msg.parent == self then
        msgBus.send(msgBus.PLAYER_HIT_RECEIVED, msg.damage)
      end
    end)
  end
}

local function handleMovement(self, dt)
  local totalMoveSpeed = self.speed + self.rootStore:get().statModifiers.moveSpeed
  local moveAmount = totalMoveSpeed * dt
  local origx, origy = self.x, self.y
  local mx, my = camera:getMousePosition()
  local mDx, mDy = Position.getDirection(self.x, self.y, mx, my)

  local nextX, nextY = self.x, self.y
  self.dir = mDx > 0 and DIRECTION_RIGHT or DIRECTION_LEFT

  if self.forceMove then
    nextX = nextX + moveAmount * mDx
    nextY = nextY + moveAmount * mDy
  end

  -- MOVEMENT
  local inputX, inputY = 0, 0
  if love.keyboard.isDown(keyMap.RIGHT) then
    inputX = 1
  end

  if love.keyboard.isDown(keyMap.LEFT) then
    inputX = -1
  end

  if love.keyboard.isDown(keyMap.UP) then
    inputY = -1
  end

  if love.keyboard.isDown(keyMap.DOWN) then
    inputY= 1
  end

  local dx, dy = Position.getDirection(0, 0, inputX, inputY)
  nextX = nextX + (dx * moveAmount)
  nextY = nextY + (dy * moveAmount)

  return nextX, nextY, totalMoveSpeed
end

local function handleAnimation(self, dt, nextX, nextY, moveSpeed)
  local moving = self.x ~= nextX or self.y ~= nextY

  -- ANIMATION STATES
  if moving then
    self.animation = self.animations.run
      :update(moveSpeed/(moveSpeed*2.5)*dt)
  else
    self.animation = self.animations.idle
      :update(dt/12)
  end
end

local function handleAbilities(self, dt)
  -- SKILL_1
  local isSkill1Activate = love.keyboard.isDown(keyMap.SKILL_1) or
    love.mouse.isDown(mouseInputMap.SKILL_1)
  if not self.clickDisabled and isSkill1Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_1')
  end

  -- SKILL_2
  local isSkill2Activate = love.keyboard.isDown(keyMap.SKILL_2) or
    love.mouse.isDown(mouseInputMap.SKILL_2)
  if not self.clickDisabled and isSkill2Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_2')
  end

  -- ACTIVE_ITEM_1
  local isItem1Activate = love.keyboard.isDown(keyMap.ACTIVE_ITEM_1)
  if not self.clickDisabled and isItem1Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'ACTIVE_ITEM_1')
  end

  -- ACTIVE_ITEM_2
  local isItem2Activate = love.keyboard.isDown(keyMap.ACTIVE_ITEM_2)
  if not self.clickDisabled and isItem2Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'ACTIVE_ITEM_2')
  end
end

function Player.update(self, dt)
  local nextX, nextY, totalMoveSpeed = handleMovement(self, dt)
  handleAnimation(self, dt, nextX, nextY, totalMoveSpeed)
  handleAbilities(self, dt)

  -- dynamically get the current animation frame's height
  local sx, sy, sw, sh = self.animation.sprite:getViewport()
  local w,h = sw, sh
  -- true center taking into account pivot
  local oX, oY = self.animation:getSourceOffset()

  -- COLLISION UPDATES
  local colOrigX, colOrigY = self.colObj.x, self.colObj.y
  local sizeOffset = 10
  self.colObj:update(
    -- use current coordinates because we only want to update size
    colOrigX,
    colOrigY,
    w,
    h - sizeOffset,
    oX,
    oY - sizeOffset
  )

  local actualX, actualY, cols, len = self.colObj:move(nextX, nextY, collisionFilter)
  self.x = actualX
  self.y = actualY
  self.h = h
  self.w = w

  -- update camera to follow player
  camera:setPosition(self.x, self.y)

  local gridX, gridY = Position.pixelsToGrid(self.x, self.y, config.gridSize)
  local dist = getDist(self.prevGridX or 0, self.prevGridY or 0, gridX, gridY)
  local shouldUpdateFlowField = dist >= 2
  if shouldUpdateFlowField and self.mapGrid then
    local flowField, callCount = Flowfield(self.mapGrid, gridX, gridY, self.isGridCellVisitable)
    msgBus.send(msgBus.NEW_FLOWFIELD, {
      flowField = flowField
    })
    self.prevGridX = gridX
    self.prevGridY = gridY
  end
end

local function drawShadow(self, sx, sy, ox, oy)
  -- SHADOW
  love.graphics.setColor(0,0,0,0.2)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y + self.h/2,
    math.rad(self.angle),
    sx,
    -sy / 2,
    ox,
    oy
  )
end

local function drawDebug(self)
  if config.collisionDebug then
    local c = self.colObj
    love.graphics.setColor(1,1,1,0.5)
    local debug = require 'modules.debug'
    debug.boundingBox(
      'fill',
      c.x - c.ox,
      c.y - c.oy,
      c.w,
      c.h,
      false
    )
  end
end

function Player.draw(self)
  local ox, oy = self.animation:getOffset()
  local scaleX, scaleY = 1 * self.dir, 1

  drawShadow(self, scaleX, scaleY, ox, oy)
  drawDebug(self)

  love.graphics.setShader(self.shader)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    math.rad(self.angle),
    scaleX,
    scaleY,
    ox,
    oy
  )
  love.graphics.setShader()
end

Player.drawOrder = function(self)
  return self.group.drawOrder(self) + 1
end

return Component.createFactory(Player)
