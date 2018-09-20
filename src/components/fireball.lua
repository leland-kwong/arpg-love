local Component = require 'modules.component'
local config = require 'config.config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Position = require 'utils.position'
local Gui = require 'components.gui.gui'
local tween = require 'modules.tween'

local colMap = collisionWorlds.map

local scale = 1
local maxLifeTime = 2

local filters = {
  obstacle = true,
  obstacle2 = true,
  ai = true
}
local function colFilter(item, other)
  if not filters[other.group] then
    return false
  end
  return 'touch'
end

local function impactCollisionFilter(item)
  if item.group == 'ai' then
    return true
  end
  return false
end

local ImpactAnimation = Component.createFactory({
  x = 0,
  y = 0,
  w = 0,
  h = 0,
  endState = {w = 0},
  color = {1,0.7,0,0.15},
  group = groups.all,
  onHit = function(self, hitMessage)
    return hitMessage
  end,
  init = function(self)
    -- shrinks the impact animation over time
    self.tween = tween.new(0.2, self, self.endState, tween.easing.inExpo)
  end,
  update = function(self, dt)
    local done = self.tween:update(dt)

    if done then
      self:delete()
    end
  end,
  draw = function(self)
    love.graphics.setColor(self.color)
    love.graphics.circle(
      'fill',
      self.x,
      self.y,
      self.w
    )
  end,
  drawOrder = function(self)
    return self.group:drawOrder(self) + 30
  end
})

local function handleImpact(self)
  local width, height = self.w * 4, self.h * 4
  local collisionX, collisionY = self.x - width/2, self.y - height/2
  local parentX, parentY = self.x, self.y

  local items, len = collisionWorlds.map:queryRect(
    collisionX,
    collisionY,
    width,
    height,
    impactCollisionFilter
  )

  for i=1, len do
    local it = items[i]
    msgBus.send(msgBus.CHARACTER_HIT, self.onHit(self, {
      parent = it.parent,
      damage = math.random(self.minDamage, self.maxDamage)
    }))
  end

  ImpactAnimation.create({
    x = parentX,
    y = parentY,
    w = width/2,
    h = height/2
  })
end

local Fireball = {
  group = groups.all,
  -- DEFAULTS
  minDamage = 2,
  maxDamage = 3,
  scale = 1,
  maxLifeTime = 2,
  speed = 400,
  startOffset = 0,
  weaponDamageScaling = 1.2,
  cooldown = 0.15,
  animation = { 'fireball' },

  init = function(self)
    local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
    -- adjust starting position based on the start offset
    self.x = self.x + self.startOffset * dx
    self.y = self.y + self.startOffset * dy

    self.direction = {x = dx, y = dy}
    self.animation = animationFactory:new(self.animation)

    local w,h = select(3, self.animation.sprite:getViewport())
    local cw, ch = 15*self.scale, 15*self.scale -- collision dimensions
    self.w = cw
    self.h = ch
    self.colObj = collisionObject
      :new('projectile', self.x, self.y, cw, ch, self.w/2, self.h/2)
      :addToWorld(collisionWorlds.map)
  end,

  update = function(self, dt)
    self.maxLifeTime = self.maxLifeTime - dt

    local dx = self.direction.x * dt * self.speed
    local dy = self.direction.y * dt * self.speed
    self.x = self.x + dx
    self.y = self.y + dy
    self.animation:update(dt)
    local cols, len = select(3, self.colObj:move(self.x, self.y, colFilter))
    local hasCollisions = len > 0
    local isExpired = self.maxLifeTime <= 0

    if hasCollisions or isExpired then
      if hasCollisions then
        for i=1, len do
          local col = cols[i]
          if col.other.group == 'ai' then
            handleImpact(self)
          end
        end
      end

      self:delete()
    end
  end,

  draw = function(self)
    local angle = math.atan2( self.direction.y, self.direction.x )
    local ox, oy = self.animation:getOffset()

    -- shadow
    love.graphics.setColor(0,0,0,0.15)
    love.graphics.draw(
      animationFactory.atlas
      , self.animation.sprite
      , self.x
      , self.y + self.h
      , angle
      , scale
      , scale / 2
      , ox
      , oy
    )

    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(
        animationFactory.atlas
      , self.animation.sprite
      , self.x
      , self.y
      , angle
      , scale
      , scale
      , ox
      , oy
    )

    if config.collisionDebug then
      local debug = require 'modules.debug'
      local c = self.aoeCollision
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
}

Fireball.drawOrder = function(self)
  local order = self.group:drawOrder(self) + 2
  return order
end

return Component.createFactory(Fireball)