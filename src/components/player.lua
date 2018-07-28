local Color = require 'modules.color'
local groups = require 'components.groups'
local config = require 'config'
local socket = require 'socket'
local inspect = require('utils.inspect')
local loadJsonFile = require 'utils.load-json-file'
local perf = require 'utils.perf'
local Animation = require 'modules.animation'

local keyMap = config.keyboard

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
      activeAnimation = nil
    }
  end,

  init = function(self)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    self.spriteAtlas = love.graphics.newImage('built/sprite.png')
    local spriteData = loadJsonFile('built/sprite.json')
    local createAnimation = Animation(spriteData, self.spriteAtlas, 2)

    self.animations = {
      idle = createAnimation({
        'character-1',
        'character-8',
        'character-9',
        'character-10',
        'character-11'
      }),
      run = createAnimation({
        'character-15',
        'character-16',
        'character-17',
        'character-18',
      })
    }

    local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
    self.shader = love.graphics.newShader(pixelOutlineShader)
    self.shader:send('sprite_size', {spriteData.meta.size.w, spriteData.meta.size.h})
    self.shader:send('outline_width', 1)
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

    self.activeAnimation = moving and self.animations.run(15) or self.animations.idle(5)
  end,

  draw = function(self)
    local aniDir = flipAnimation and -1 or 1
    local sprite = self.activeAnimation()
    local x,y,w = sprite:getViewport()
    local scale = 3
    local angle = 0
    local offsetX = (w/2) * aniDir * scale

    love.graphics.setShader(self.shader)
    love.graphics.draw(
      self.spriteAtlas,
      sprite,
      self.x - offsetX,
      self.y,
      math.rad(angle),
      scale * aniDir,
      scale
    )
    love.graphics.setShader()
  end
})

playerFactory.create()