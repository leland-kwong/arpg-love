local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'
local tick = require 'utils.tick'
local collisionGroups = require 'modules.collision-groups'

local frostShotSoundFilter = {
  type = 'lowpass',
  volume = .25,
}

local playFrostShotSound = debounce(function()
  local Sound = require 'components.sound'
  local source = Sound.FROST_SHOT
  source:setFilter(frostShotSoundFilter)
  love.audio.stop(source)
  love.audio.play(source)
end, 0.3)

local function onDestroyStart()
  local Sound = require 'components.sound'
  love.audio.play(Sound.functions.robotDestroyed())
end

-- deals damage with a chance to slow
local FrostShot = {
  range = 10,
  attackTime = 0.3,
  cooldown = 0.8
}

function FrostShot.use(self, _, targetX, targetY)
  local Attack = require 'components.abilities.frost-spark'
  local projectile = Attack.create({
      debug = false
    , x = self.x
    , y = self.y - self.z
    , x2 = targetX
    , y2 = targetY
    , speed = 115
    , lifeTime = 60
    , targetGroup = collisionGroups.player
    , minDamage = 1
    , maxDamage = 2
    , drawOrder = function()
      return self.drawOrder(self) + 1
    end
  })
  playFrostShotSound()
  return skill
end


return function()
  local animations = {
    idle = animationFactory:new({
      'eyeball'
    }),
    moving = animationFactory:new({
      'eyeball'
    })
  }

  local spriteWidth, spriteHeight = animations.idle:getSourceSize()

  local heightChange = 4
  local dataSheet = {
    name = 'i-229',
    properties = {
      'ranged',
      'slow on hit'
    }
  }
  return {
    dataSheet = dataSheet,
    -- debug = true,
    scale = 1,
    z = 10,
    itemData = {
      level = 1,
      dropRate = 20
    },
    heightOffset = math.random(0, heightChange),
    heightChange = heightChange,
    moveSpeed = 100,
    maxHealth = 17,
    experience = 1,
    w = spriteWidth,
    h = spriteHeight,
    animations = animations,
    armor = 250,
    abilities = {
      FrostShot
    },
    attackRange = 10,
    onUpdateStart = function(self, dt)
      self.heightOffset = self.heightOffset + (dt * self.heightChange)
      if self.heightOffset >= 4 then
        self.heightChange = math.abs(self.heightChange) * -1
      end
      if self.heightOffset <= 0 then
        self.heightChange = math.abs(self.heightChange)
      end
      -- update z position for levitation effect
      self:setPosition(
        self.x,
        self.y,
        self.z + dt * self.heightChange
      )
    end,
    onDestroyStart = onDestroyStart
  }
end