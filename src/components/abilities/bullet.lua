local Component = require 'modules.component'
local config = require 'config'
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

local colMap = collisionWorlds.map

local defaultFilters = {
  obstacle = true,
  obstacle2 = true,
}

local ColFilter = memoize(function(groupToMatch)
  return function (item, other)
    if (other.group ~= groupToMatch) and not defaultFilters[other.group] then
      return false
    end
    return 'touch'
  end
end)

local Bullet = {
  group = groups.all,
  -- DEFAULTS
  minDamage = 1,
  maxDamage = 2,
  scale = 1,
  lifeTime = 2,
  speed = 250,
  cooldown = 0.1,
  targetGroup = nil,

  init = function(self)
    typeCheck.validate(self.targetGroup, typeCheck.STRING)

    local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
    self.direction = {x = dx, y = dy}

    self.damage = math.random(self.minDamage, self.maxDamage)
    self.animation = animationFactory:new({
      'bullet-1'
    })

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
          if col.other.group == self.targetGroup then
            msgBus.send(msgBus.CHARACTER_HIT, {
              parent = col.other.parent,
              damage = self.damage
            })
          end
        end
      end

      self:delete()
    end
  end,

  draw = function(self)
    local angle = 0
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

    love.graphics.setColor(Color.rgba255(244, 220, 66, 1))
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

Bullet.drawOrder = function(self)
  local order = self.group.drawOrder(self) + 2
  return order
end

return Component.createFactory(Bullet)