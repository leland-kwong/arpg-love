local Animation = require 'modules.animation'
local json = require 'lua_modules.json'
local bump = require 'modules.bump'
local collisionObject = require 'modules.collision'

local world = bump.newWorld(32)

local scale = 4
love.graphics.setDefaultFilter('nearest', 'nearest')
local spriteAtlas = love.graphics.newImage('built/sprite.png')
local spriteData = json.decode(
  love.filesystem.read('built/sprite.json')
)
local animationFactory = Animation(spriteData, spriteAtlas, 1)

local function screenCenter(scale)
  return
    love.graphics.getWidth()/2/scale,
    love.graphics.getHeight()/2/scale
end

local idleAnimation = animationFactory:new({
  'character-1',
  'character-8',
  'character-9',
  'character-10',
  'character-11'
})

local runAnimation = animationFactory:new({
  'character-15',
  'character-16',
  'character-17',
  'character-18',
})

local fireballAnimation = animationFactory:new({
  'fireball'
})

local tileAnimation = animationFactory:new({
  'wall'
})

-- GAME STATE
local startX, startY = screenCenter(scale)
local state = {
  player = {
    x = startX,
    y = startY,
    w = idleAnimation:getWidth(),
    h = idleAnimation:getHeight(),
    animation = idleAnimation,
    collisionObject = nil
  },
  wall = {
    x = startX + 50,
    y = startY,
    w = tileAnimation:getSourceSize(),
    h = select(2, tileAnimation:getSourceSize()),
    collisionObject = nil
  },
  debug = {
    collision = true,
    spriteBoundingBox = true
  }
}

local pixelOutlineShader = love.filesystem.read('shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = animationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)
shader:send('outline_color', outlineColor)

function love.load()
  love.window.setTitle('sprite and collision detection demo')
  love.keyboard.setKeyRepeat(true)

  local playerOffX, playerOffY = idleAnimation:getSourceOffset()
  state.player.collisionObject = collisionObject:new(
    'player',
    state.player.x,
    state.player.y,
    state.player.w,
    state.player.h,
    playerOffX,
    playerOffY
  ):addToWorld(world)

  local tileOffX, tileOffY = tileAnimation:getSourceOffset()
  state.wall.collisionObject = collisionObject:new(
    'wall',
    state.wall.x,
    state.wall.y,
    state.wall.w,
    state.wall.h,
    tileOffX,
    tileOffY
  ):addToWorld(world)
end

function love.update(dt)
  local moving = false
  local dx, dy = 0, 0
  local isDown = love.keyboard.isDown

  if isDown('escape') then
    love.event.quit()
  end

  if isDown('w') then
    dy = -1
    moving = true
  end

  if isDown('s') then
    dy = 1
    moving = true
  end

  if isDown('a') then
    dx = -1
    moving = true
  end

  if isDown('d') then
    dx = 1
    moving = true
  end

  state.player.animation = moving and
    runAnimation:update(dt / 3) or
    idleAnimation:update(dt / 12)

  local ox,oy = state.player.animation:getSourceOffset()
  state.player.collisionObject:update(
    state.player.x,
    state.player.y,
    state.player.w,
    state.player.h,
    ox,
    oy
  )

  local actualX, actualY, cols = state.player.collisionObject:move(
    state.player.x + dx,
    state.player.y + dy
  )
  state.player.x = actualX
  state.player.y = actualY
end

local function drawAnimation(animation, x, y, angle, scaleX, scaleY)
  local ox,oy = animation:getOffset()
  love.graphics.draw(
    animation.atlas,
    animation.sprite,
    x,
    y,
    angle,
    scaleX,
    scaleY,
    ox,
    oy
  )
end

local function drawSpriteDebug(animation, x, y, scaleX, scaleY)
  if not state.debug.spriteBoundingBox then
    return
  end

  local ox, oy = animation:getOffset()
  local _x,_y,w,h = animation.sprite:getViewport()
  love.graphics.setColor(1,1,1,0.2)
  love.graphics.rectangle(
    'fill',
    x-ox,y-oy,
    w * (scaleX or 1),
    h * (scaleY or 1)
  )

  -- pivot point
  love.graphics.setColor(1,0.2,0.2,0.5)
  love.graphics.circle(
    'fill',
    x,y,
    1
  )

  love.graphics.setColor(1,1,1,1)
end

local function drawCollisionDebug(obj)
  if not state.debug.collision then
    return
  end

  love.graphics.setColor(0,0.7,1,0.6)
  love.graphics.rectangle(
    'fill',
    obj.x - obj.ox,
    obj.y - obj.oy,
    obj.w,
    obj.h
  )
end

local function drawPlayer(playerState)
  local x, y, animation =
    playerState.x,
    playerState.y,
    playerState.animation
  local gfx = love.graphics
  gfx.setShader(shader)
  drawAnimation(animation, x, y, math.rad(0))
  gfx.setShader()

  drawSpriteDebug(idleAnimation, x, y)
  drawCollisionDebug(playerState.collisionObject)
end

local function drawFireball()
  local gfx = love.graphics
  local x,y = screenCenter(scale)

  local posx, posy = x, y + 30
  gfx.setColor(1,1,1,1)
  gfx.setShader(shader)
  drawAnimation(fireballAnimation, posx, posy, math.rad(0))
  gfx.setShader()
  drawSpriteDebug(fireballAnimation, posx, posy)
end

local function drawTile(wallState)
  local x, y = wallState.x, wallState.y
  local gfx = love.graphics
  gfx.setColor(1,1,1,1)
  -- gfx.setShader(shader)
  drawAnimation(tileAnimation, x, y, math.rad(0))
  gfx.setShader()

  drawSpriteDebug(tileAnimation, x, y)
  drawCollisionDebug(wallState.collisionObject)
end

function love.draw()
  local gfx = love.graphics

  gfx.clear(0.3,0.3,0.3,1)
  gfx.scale(scale)
  drawPlayer(state.player)
  drawFireball()
  drawTile(state.wall)

end