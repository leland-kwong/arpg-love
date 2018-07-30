local config = require 'config'
local groups = require 'components.groups'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local gameWorld = require 'components.game-world'

local colMap = collisionWorlds.map

-- DEFAULTS
local speed = 500
local scale = 1
local maxLifeTime = 2

-- direction normalization
local function direction(x1, y1, x2, y2)
  local a = y2 - y1
  local b = x2 - x1
  local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
  return b/c, a/c
end

local filters = {
  obstacle = true,
}
local function colFilter(item, other)
  if not filters[other.type] then
    return false
  end
  return 'touch'
end

local Fireball = {
  getInitialProps = function(props)
    local dx, dy = direction(props.x, props.y, props.x2, props.y2)
    props.direction = {x = dx, y = dy}
    props.speed = speed
    props.maxLifeTime = maxLifeTime
    return props
  end,

  init = function(self)
    self.animation = animationFactory.create({
      'fireball'
    })
    self.sprite = self.animation.next(0)

    local w,h = select(3, self.sprite:getViewport())
    local cw, ch = 15*scale, 15*scale -- collision dimensions
    self.w = cw
    self.h = ch
    colMap:add(self, self.x - self.w/2, self.y - self.w/2, cw, ch)
  end,

  update = function(self, dt)
    self.maxLifeTime = self.maxLifeTime - dt

    local dx = self.direction.x * dt * self.speed
    local dy = self.direction.y * dt * self.speed
    self.x = self.x + dx
    self.y = self.y + dy
    self.sprite = self.animation.next(dt)
    local cols, len = select(3, colMap:move(self, self.x - self.w/2, self.y - self.h/2, colFilter))
    -- local len = 0
    if len > 0 or self.maxLifeTime <= 0 then
      groups.all.delete(self)
    end
  end,

  draw = function(self)
    local angle = math.atan2( self.direction.y, self.direction.x )
    local ox, oy = self.animation.getOffset()

    love.graphics.setColor(0,0,0,0.15)
    love.graphics.draw(
      animationFactory.spriteAtlas
      , self.sprite
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
        animationFactory.spriteAtlas
      , self.sprite
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
    colMap:remove(self)
  end
}

local factory = groups.all.createFactory(function(defaults)
  -- set order a little above default
  Fireball.drawOrder = function(self)
    local order = defaults.drawOrder(self) + 1
    return order
  end
  return Fireball
end)

return factory