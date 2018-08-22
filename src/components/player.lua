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

local width, height = love.window.getMode()
local startPos = {
  x = config.gridSize * 3,
  y = config.gridSize * 3,
}

local frameRate = 60
local speed = 400 -- per frame

local activeAnimation
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

local skillHandlers = {
  SKILL_1 = (function()
    local curCooldown = 0
    local skill = {}

    local floor = math.floor
    local function modifyAbility(instance, modifiers)
      local v = instance
      local m = modifiers
      local percentDamage = m.percentDamage
			local energyCost = v.energyCost
			local baseWeapon = m.weaponDamage
			local totalWeaponDmg = (1 + v.weaponDamageScaling) * baseWeapon
			local multiplier = 1 + m.percentDamage
			local min = floor((v.minDamage * multiplier) + m.flatDamage + totalWeaponDmg)
      local max = floor((v.maxDamage * multiplier) + m.flatDamage + totalWeaponDmg)

      -- update instance properties
      v:setProp('minDamage', min)
       :setProp('maxDamage', max)
       :setProp('cooldown', v.cooldown - (v.cooldown * m.cooldownReduction))

      return v
    end

    function skill.use(self)
      if curCooldown > 0 then
        return skill
      else
        local Fireball = require 'components.fireball'
        local mx, my = camera:getMousePosition()
        local projectile = modifyAbility(
          Fireball.create({
              debug = false
            , x = self.x
            , y = self.y
            , x2 = mx
            , y2 = my
          }),
          self.rootStore:get().statModifiers
        )
        curCooldown = projectile.cooldown
        return skill
      end
    end

    function skill.updateCooldown(dt)
      curCooldown = curCooldown - dt
      return skill
    end

    return skill
  end)()
}

local Player = {
  group = groups.all,
  x = startPos.x,
  y = startPos.y,
  pickupRadius = 5 * config.gridSize,

  -- collision properties
  type = 'player',
  h = 1,
  w = 1,
  mapGrid = nil,

  init = function(self)
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

      if msgBus.ITEM_PICKUP == msgType then
        local item = msg
        local dist = calcDist(self.x, self.y, item.x, item.y)
        local outOfRange = dist > self.pickupRadius
        local gridX1, gridY1 = Position.pixelsToGrid(self.x, self.y, config.gridSize)
        local gridX2, gridY2 = Position.pixelsToGrid(item.x, item.y, config.gridSize)
        local canWalkToItem = LineOfSight(self.mapGrid, Map.WALKABLE)(gridX1, gridY1, gridX2, gridY2)
        if outOfRange or (not canWalkToItem) then
          self.clickDisabled = true
          -- move towards item
          self.forceMove = true
        elseif canWalkToItem then
          self.forceMove = false
          item:pickup()
        end
      elseif (msgBus.ITEM_PICKUP_CANCEL == msgType) or (msgBus.ITEM_PICKUP_SUCCESS == msgType) then
        self.forceMove = false
        self.clickDisabled = false
      end

      if msgBus.ITEM_HOVERED == msgType then
        self.clickDisabled = msg
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
  end,

  update = function(self, dt)
    local moveAmount = speed * dt
    local origx, origy = self.x, self.y
    local mx, my = camera:getMousePosition()
    local dx, dy = Position.getDirection(self.x, self.y, mx, my)
    local nextX, nextY = self.x, self.y
    self.dir = dx > 0 and DIRECTION_RIGHT or DIRECTION_LEFT

    if self.forceMove then
      nextX = nextX + moveAmount * dx
      nextY = nextY + moveAmount * dy
    end

    -- MOVEMENT
    if love.keyboard.isDown(keyMap.RIGHT) then
      nextX = nextX + moveAmount
    end

    if love.keyboard.isDown(keyMap.LEFT) then
      nextX = nextX - moveAmount
    end

    if love.keyboard.isDown(keyMap.UP) then
      nextY = nextY - moveAmount
    end

    if love.keyboard.isDown(keyMap.DOWN) then
      nextY = nextY + moveAmount
    end

    local moving = self.x ~= nextX or self.y ~= nextY

    -- ANIMATION STATES
    if moving then
      self.animation = self.animations.run
        :update(dt/2)
    else
      self.animation = self.animations.idle
        :update(dt/12)
    end

    -- SKILL_1
    local isSkill1Activate = love.keyboard.isDown(keyMap.SKILL_1) or
      love.mouse.isDown(mouseInputMap.SKILL_1)
    if not self.clickDisabled and isSkill1Activate then
      skillHandlers.SKILL_1.use(self)
    end
    skillHandlers.SKILL_1.updateCooldown(dt)

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
}

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
