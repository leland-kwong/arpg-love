local socket = require 'socket'
local inspect = require('utils.inspect')
local loadJsonFile = require 'utils.load-json-file'
local memoize = require 'utils.memoize'

local width, height = love.window.getMode()
local position = {
  x = width / 2,
  y = height / 2
}

local keyboard = {
  UP = 'w',
  RIGHT = 'd',
  DOWN = 's',
  LEFT = 'a'
}

local sprite
local spriteAtlas
local spriteData
local frameRate = 60
local speed = 5 * frameRate -- per frame

-- returns a hash of animations by name with a value set to a coroutine
local function Animation(frames, frameJson, spriteAtlas)
  local animation = {}
  for aniName, aniFrames in pairs(frames) do
    animation[aniName] = memoize(function(fps)
      local frameRate = 60
      local maxFrames = #aniFrames
      local firstFrame = frameJson.frames[aniFrames[1]]
      local w = firstFrame.sourceSize.w
      local h = firstFrame.sourceSize.h
      local sprite = love.graphics.newQuad(0, 0, w, h, spriteAtlas:getDimensions())
      local co = function()
        local tick = 0
        local index = 1 -- frame index
        local every = frameRate / fps -- new index after every `x` ticks
        while true do
          if every == tick then
            tick = 0
            index = index + 1
            if index > maxFrames then
              index = 1
            end
          end
          local frameKey = aniFrames[index]
          local frame = frameJson.frames[frameKey]
          -- readjust position if the height is less
          local offsetY = frame.sourceSize.h - frame.frame.h
          sprite:setViewport(frame.frame.x, frame.frame.y - offsetY, frame.sourceSize.w, frame.sourceSize.h)
          coroutine.yield(sprite)
          tick = tick + 1
        end
      end
      return coroutine.wrap(co)
    end)
  end
  return animation
end

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

function love.update(dt)
  local moveAmount = speed * dt
  local moving = false
  if love.keyboard.isDown(keyboard.RIGHT) then
    position.x = position.x + moveAmount
    moving = true
    flipAnimation = false
  end

  if love.keyboard.isDown(keyboard.LEFT) then
    position.x = position.x - moveAmount
    moving = true
    flipAnimation = true
  end

  if love.keyboard.isDown(keyboard.UP) then
    position.y = position.y - moveAmount
    moving = true
  end

  if love.keyboard.isDown(keyboard.DOWN) then
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