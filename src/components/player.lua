local Color = require 'modules.color'
local groups = require 'components.groups'
local config = require 'config'
local animationFactory = require 'components.animation-factory'

local keyMap = config.keyboard
local mouseInputMap = config.mouseInputMap

local width, height = love.window.getMode()
local startPos = {
  x = width / 2,
  y = height / 2
}

local frameRate = 60
local speed = 5 * frameRate -- per frame

local activeAnimation
local flipAnimation = false

local playerFactory = groups.all.createFactory({
  getInitialProps = function(initialProps)
    return {
      x = startPos.x,
      y = startPos.y,
    }
  end,

  init = function(self)
    self.animations = {
      idle = animationFactory.create({
        'character-1',
        'character-8',
        'character-9',
        'character-10',
        'character-11'
      }),
      run = animationFactory.create({
        'character-15',
        'character-16',
        'character-17',
        'character-18',
      })
    }

    local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
    self.outlineColor = {1,1,1,1}
    self.shader = love.graphics.newShader(pixelOutlineShader)
    local spriteData = animationFactory.spriteData
    self.shader:send('sprite_size', {spriteData.meta.size.w, spriteData.meta.size.h})
    self.shader:send('outline_width', 1)
    self.shader:send('outline_color', self.outlineColor)
  end,

  update = function(self, dt)
    local moveAmount = speed * dt
    local moving = false

    if love.keyboard.isDown(keyMap.RIGHT) then
      self.x = self.x + moveAmount
      moving = true
      flipAnimation = false
    end

    if love.keyboard.isDown(keyMap.LEFT) then
      self.x = self.x - moveAmount
      moving = true
      flipAnimation = true
    end

    if love.keyboard.isDown(keyMap.UP) then
      self.y = self.y - moveAmount
      moving = true
    end

    if love.keyboard.isDown(keyMap.DOWN) then
      self.y = self.y + moveAmount
      moving = true
    end

    if moving then
      local a = self.animations.run
      self.animation = a
      self.sprite = a.next(dt / 4)
    else
      local a = self.animations.idle
      self.animation = a
      self.sprite = a.next(dt / 12)
    end

    if love.keyboard.isDown(keyMap.SKILL_1) or love.mouse.isDown(mouseInputMap.SKILL_1) then
      local fireball = require 'components.fireball'
      fireball.create({
          debug = false
        , x = self.x
        , y = self.y
        , x2 = love.mouse.getX()
        , y2 = love.mouse.getY()
      })
    end
  end,

  draw = function(self)
    local ox, oy = self.animation.getOffset()
    local scale = config.scaleFactor
    local aniDir = flipAnimation and -1 or 1

    love.graphics.setShader(self.shader)
    love.graphics.draw(
      animationFactory.spriteAtlas,
      self.sprite,
      self.x,
      self.y,
      math.rad(self.angle),
      scale * aniDir,
      scale,
      ox,
      oy
    )
    love.graphics.setShader()

    if self.debug then
      local w,h = select(3, self.sprite:getViewport())
      local rw, rh = w*scale, h*scale
      love.graphics.setColor(1,1,1,0.5)
      -- DEBUG SHAPES
      local debug = require 'modules.debug'
      debug.boundingBox(self.x, self.y, rw, rh)
      love.graphics.setColor(1,1,1,1)
    end
  end
})

playerFactory.create({ debug = false })