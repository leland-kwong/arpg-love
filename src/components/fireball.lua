local config = require 'config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Position = require 'utils.position'

local colMap = collisionWorlds.map

-- DEFAULTS
local speed = 500
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

local Fireball = {
  damage = 1,

  getInitialProps = function(props)
    local dx, dy = Position.getDirection(props.x, props.y, props.x2, props.y2)
    props.direction = {x = dx, y = dy}
    props.speed = speed
    props.maxLifeTime = maxLifeTime
    return props
  end,

  init = function(self)
    self.animation = animationFactory:new({
      'fireball'
    })

    local w,h = select(3, self.animation.sprite:getViewport())
    local cw, ch = 15*scale, 15*scale -- collision dimensions
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
          msgBus.send(msgBus.CHARACTER_HIT, {
            parent = col.other.parent,
            damage = self.damage
          })
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
      debug.boundingBox('fill', self.x, self.y, self.w, self.h)
    end
  end,

  final = function(self)
    self.colObj:delete()
  end
}

local factory = groups.all.createFactory(function(defaults)
  -- set order a little above default
  Fireball.drawOrder = function(self)
    local order = defaults.drawOrder(self) + 2
    return order
  end
  return Fireball
end)

return factory