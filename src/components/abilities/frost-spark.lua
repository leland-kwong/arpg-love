local Component = require 'modules.component'
local config = require 'config.config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Position = require 'utils.position'
local Color = require 'modules.color'
local memoize = require 'utils.memoize'
local typeCheck = require 'utils.type-check'
local random = math.random

local colMap = collisionWorlds.map

local defaultFilters = {
  obstacle = true,
}

local ColFilter = memoize(function(groupToMatch)
  return function (item, other)
    if (other.group ~= groupToMatch) and not defaultFilters[other.group] then
      return false
    end
    return 'touch'
  end
end)

local FrostSpark = {
  group = groups.all,

  -- [DEFAULTS]

  -- start position
  x = 0,
  y = 0,

  -- target position
  x2 = 0,
  y2 = 0,
  minDamage = 1,
  maxDamage = 2,
  startOffset = 0,
  scale = 1,
  lifeTime = 2,
  speed = 250,
  cooldown = 0.1,
  targetGroup = nil,
  hits = 0,
  maxHits = 1,
  color = Color.WHITE,

  init = function(self)
    assert(
      type(self.targetGroup) == 'string' and self.targetGroup ~= nil,
      '[FrostSpark] `targetGroup` is required'
    )

    local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
    self.direction = {x = dx, y = dy}
    self.x = self.x + self.startOffset * dx
    self.y = self.y + self.startOffset * dy

    self.animation = animationFactory:newStaticSprite('frost-spark')

    local w,h = select(3, self.animation.sprite:getViewport())
    local ox, oy = self.animation:getOffset()
    self.w = w
    self.h = h
    self.colObj = collisionObject
      :new('projectile', self.x, self.y, w, h, ox, oy)
      :addToWorld(collisionWorlds.map)
  end,

  update = function(self, dt)
    self.lifeTime = self.lifeTime - dt

    local lw = Component.get('lightWorld')
    lw:addLight(self.x, self.y, 5)

    local dx = self.direction.x * dt * self.speed
    local dy = self.direction.y * dt * self.speed
    self.x = self.x + dx
    self.y = self.y + dy
    self.animation:update(dt)
    local cols, len = select(3, self.colObj:move(self.x, self.y, ColFilter(self.targetGroup)))
    local hasCollisions = len > 0
    local isExpired = self.lifeTime <= 0

    if hasCollisions or isExpired then
      if hasCollisions then
        for i=1, len do
          local col = cols[i]
          if (self.hits < self.maxHits) and (col.other.group == self.targetGroup) then
            -- slow effect
            msgBus.send(msgBus.CHARACTER_HIT, {
              parent = col.other.parent,
              duration = 1,
              modifiers = {
                moveSpeed = function(target)
                  return target:getBaseStat('moveSpeed') * -0.5
                end,
              },
              source = 'FROST_SPARK_SLOW'
            })
            -- damage
            msgBus.send(msgBus.CHARACTER_HIT, {
              parent = col.other.parent,
              damage = random(self.minDamage, self.maxDamage),
            })
            self.hits = self.hits + 1
          end
        end
      end
      if isExpired or (self.hits <= self.maxHits) then
        self:delete()
      end
    end
  end,

  draw = function(self)
    self.angle = self.angle + math.pi/30
    local angle = self.angle
    local ox, oy = self.animation:getOffset()
    local scale = self.scale

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

    love.graphics.setColor(self.color)
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
      local co = self.colObj
      debug.boundingBox('fill', co.x - co.ox, co.y - co.oy, co.w, co.h, false)
    end
  end,

  final = function(self)
    self.colObj:delete()
  end
}

FrostSpark.drawOrder = function(self)
  local drawOrders = require 'modules.draw-orders'
  return drawOrders.FrostSparkDraw
end

return Component.createFactory(FrostSpark)