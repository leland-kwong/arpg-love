require 'modules.autobatch'
local socket = require 'socket'
local inspect = require('utils.inspect')
local loadJsonFile = require 'utils.load-json-file'
local perf = require 'utils.perf'
local config = require 'config'
local Animation = require 'modules.animation'

local width, height = love.window.getMode()
local position = {
  x = width / 2,
  y = height / 2
}

local sprite
local spriteAtlas
local spriteData
local frameRate = 60
local speed = 5 * frameRate -- per frame

local animations = {}
local activeAnimation
local flipAnimation = false

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')
  spriteAtlas = love.graphics.newImage('assets/built/sprite.png')
  spriteData = loadJsonFile('assets/built/sprite.json')

  local frames = {
    idle = {
      'character-1',
      'character-8',
      'character-9',
      'character-10',
      'character-11'
    },
    run = {
      'character-15',
      'character-16',
      'character-17',
      'character-18',
    }
  }

  animations = Animation(frames, spriteData, spriteAtlas)
end

local keyMap = config.keyboard
function love.update(dt)
  local moveAmount = speed * dt
  local moving = false
  if love.keyboard.isDown(keyMap.RIGHT) then
    position.x = position.x + moveAmount
    moving = true
    flipAnimation = false
  end

  if love.keyboard.isDown(keyMap.LEFT) then
    position.x = position.x - moveAmount
    moving = true
    flipAnimation = true
  end

  if love.keyboard.isDown(keyMap.UP) then
    position.y = position.y - moveAmount
    moving = true
  end

  if love.keyboard.isDown(keyMap.DOWN) then
    position.y = position.y + moveAmount
    moving = true
  end

  activeAnimation = moving and animations.run(15) or animations.idle(5)
end

function love.draw()
  -- background
  love.graphics.clear(0.2,0.2,0.2)

  local aniDir = flipAnimation and -1 or 1
  local sprite = activeAnimation()
  local x,y,w = sprite:getViewport()
  local scale = 3
  local angle = 0
  local offsetX = (w/2) * aniDir * scale
  love.graphics.draw(
    spriteAtlas,
    sprite,
    position.x - offsetX,
    position.y,
    math.rad(angle),
    scale * aniDir,
    scale
  )
end