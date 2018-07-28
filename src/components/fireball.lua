local config = require 'config'
local groups = require 'components.groups'
local animationFactory = require 'components.animation-factory'

-- direction normalization
local function direction(x1, y1, x2, y2)
  local a = y2 - y1
  local b = x2 - x1
  local c = math.sqrt(math.pow(a, 2) + math.pow(b, 2))
  return b/c, a/c
end

local factory = groups.all.createFactory({
  getInitialProps = function(props)
    local dx, dy = direction(props.x, props.y, props.x2, props.y2)
    props.direction = {x = dx, y = dy}
    props.speed = 300
    return props
  end,

  init = function(self)
    self.animation = animationFactory.create({
      'fireball'
    })
  end,

  update = function(self, dt)
    self.x = self.x + self.direction.x * dt * self.speed
    self.y = self.y + self.direction.y * dt * self.speed
    self.sprite = self.animation.next(dt)
  end,

  draw = function(self)
    local angle = math.atan2( self.direction.y, self.direction.x )
    local scale = config.scaleFactor
    local ox, oy = self.animation.getOffset()
    love.graphics.draw(
        animationFactory.spriteAtlas
      , self.sprite
      , self.x
      , self.y
      , angle
      , scale
      , scale
      , 0
      , oy
    )

    if self.debug then
      local w,h = select(3, self.sprite:getViewport())
      local rw, rh = w*scale, h*scale
      local debug = require 'modules.debug'
      love.graphics.setColor(1,0,1,1)
      debug.boundingBox(self.x, self.y, rw, rh)
      love.graphics.line(
          self.x
        , self.y
        , self.x2
        , self.y2
      )
      love.graphics.setColor(1,1,1,1)
    end
  end
})

return factory