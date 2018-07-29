local Color = require 'modules.color'
local groups = require 'components.groups'
local config = require 'config'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'

local colMap = collisionWorlds.map

local keyMap = config.keyboard
local mouseInputMap = config.mouseInputMap

local width, height = love.window.getMode()
local startPos = {
  x = width / 2,
  y = height / 2,
}

local frameRate = 60
local speed = 5 * frameRate -- per frame

local activeAnimation
local flipAnimation = false

local function collisionFilter(item, other)
  if other.type ~= 'obstacle' then
    return false
  end
  return 'slide'
end

local skillHandlers = {
  SKILL_1 = (function()
    local cooldown = 0.01
    local curCooldown = 0
    local skill = {}

    function skill.use(self)
      if curCooldown > 0 then
        return skill
      else
        local fireball = require 'components.fireball'
        local col = self.collisionObj
        fireball.create({
            debug = false
          , x = col.x
          , y = col.y
          , x2 = love.mouse.getX()
          , y2 = love.mouse.getY()
        })
        curCooldown = cooldown
        return skill
      end
    end

    function skill.updateCooldown(dt)
      curCooldown = curCooldown - dt
      return skill
    end

    return skill
  end)()
}

local playerFactory = groups.all.createFactory({
  getInitialProps = function()
    return {
      x = startPos.x,
      y = startPos.y,
    }
  end,

  init = function(self)
    self.collisionObj = {
      name = 'PLAYER',
      type = 'player',
      x = 0,
      y = 0,
      w = 1,
      h = 1
    }
    colMap:add(
      self.collisionObj,
      self.collisionObj.x,
      self.collisionObj.y,
      self.collisionObj.w,
      self.collisionObj.h
    )

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

  -- zDepth = function(self)
  --   return 700
  -- end,

  update = function(self, dt)
    local moveAmount = speed * dt
    local moving = false
    local origx, origy = self.x, self.y

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

    -- SKILL_1
    if love.keyboard.isDown(keyMap.SKILL_1) or love.mouse.isDown(mouseInputMap.SKILL_1) then
      skillHandlers.SKILL_1.use(self)
    end
    skillHandlers.SKILL_1.updateCooldown(dt)

    local sw,sh = self.animation.getWidth(), self.animation.getHeight()
    local scale = config.scaleFactor
    local w,h = sw*scale, sh*scale
    -- true center taking into account pivot
    local nextx, nexty = self.x, self.y
    local oX, oY = -w/2, -h/2
    local col = self.collisionObj

    colMap:update(
      self.collisionObj,
      -- use current coordinates because we only want to update size
      origx + oX,
      origy + oY,
      w,
      h
    )
    col.w = w
    col.h = h

    local actualX, actualY = colMap:move(col, nextx + oX, nexty + oY, collisionFilter)
    self.x = actualX - oX
    self.y = actualY - oY
    col.x = self.x
    col.y = self.y
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
      oy - self.animation.getHeight()/2
    )

    love.graphics.setShader()

    if config.collisionDebug then
      love.graphics.setColor(1,1,1,0.5)
      local debug = require 'modules.debug'
      local col = self.collisionObj
      debug.boundingBox('fill', self.x, self.y, col.w, col.h)
    end
  end
})

return playerFactory