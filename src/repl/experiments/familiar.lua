local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local json = require 'lua_modules.json'
local Animation = dynamicRequire 'modules.animation'

local spriteAtlas = love.graphics.newImage('built/sprite.png')
spriteAtlas:setFilter('nearest')
local spriteData = json.decode(
  love.filesystem.read('built/sprite.json')
)
local AnimationFactory = Animation(
  spriteData, spriteAtlas, 2
)

Component.create({
  id = 'familiar-test',
  x = 150,
  y = 100,
  init = function(self)
    -- Component.addToGroup(self, 'gui')
    self.animationInner = AnimationFactory:newStaticSprite('companion/inner')
    self.animationOuter = AnimationFactory:newStaticSprite('companion/outer')

    self.outerAngle = 0
    self.clock = 0

    local tween = require 'modules.tween'
    self.rotTween = tween.new(3, self, { outerAngle = math.pi }, tween.easing.inOutQuart)
    self.rotDirection = 1
  end,

  update = function(self, dt)
    self.clock = self.clock + dt
    self.z = math.sin(self.clock) * 2
    local complete = self.rotTween:update(dt)
    if complete then
      self.rotDirection = self.rotDirection * -1
      self.rotTween:reset()
    end
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.clear(0.1,0.1,0.1)
    love.graphics.origin()
    love.graphics.scale(3)

    -- love.graphics.setColor(1,0.5,1)
    local math = require 'utils.math'
    local x, y = math.round(self.x) + 0.5, math.round(self.y) + 0.5
    self.animationOuter:draw(x, y + self.z, self.outerAngle * self.rotDirection)
    self.animationInner:draw(x, y + self.z)

    love.graphics.pop()
  end,

  drawOrder = function(self)
    return math.pow(10, 10)
  end
})