local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'
local collisionGroups = require 'modules.collision-groups'

local blastSoundFilter = {
  type = 'lowpass',
  volume = .4,
}

local playblasterSound = debounce(function()
  local Sound = require 'components.sound'
  local source = Sound.BLASTER_2
  source:setFilter(blastSoundFilter)
  love.audio.stop(source)
  love.audio.play(source)
end, 0.2)

local function onDestroyStart()
  local Sound = require 'components.sound'
  love.audio.play(Sound.functions.robotDestroyed())
end

local PelletShot = {
  range = 8,
  attackTime = 0.25,
  cooldown = 0.8
}

function PelletShot.use(self, state, targetX, targetY)
  local Attack = require 'components.abilities.bullet'
  local projectile = Attack.create({
      debug = false
    , x = self.x
    , y = self.y
    , x2 = targetX
    , y2 = targetY
    , lifetime = 60
    , speed = 125
    , targetGroup = collisionGroups.create(collisionGroups.player, collisionGroups.obstacle)
    , minDamage = 9
    , maxDamage = 12
  })
  playblasterSound()

  state.isNewAttack = true
  state.clock = 0
end

function PelletShot.update(self, state, dt)
  self.animation = state.isNewAttack
    and self.animations.attacking
    or self.animations.idle
  if state.isNewAttack then
    state.clock = state.clock + dt
    local isAbilityComplete = state.clock >= PelletShot.attackTime
    if isAbilityComplete then
      state.isNewAttack = false
    end
    return (not isAbilityComplete)
  end
  return false
end

return function()
  local animations = {
    attacking = animationFactory:new({
      'ai-1/ai-6'
    }),
    moving = animationFactory:new({
      'ai-1/ai-0',
      'ai-1/ai-1',
      'ai-1/ai-2',
      'ai-1/ai-3',
      'ai-1/ai-4',
      'ai-1/ai-5',
    }):setDuration(1),
    idle = animationFactory:new({
      'ai-1/ai-6',
      'ai-1/ai-7',
      'ai-1/ai-8',
      'ai-1/ai-9'
    }):setDuration(0.6)
  }

  local attackRange = 8
  local spriteWidth, spriteHeight = animations.idle:getSourceSize()
  local dataSheet = {
    name = 'minibot',
    properties = {
      'ranged'
    }
  }

  return {
    dataSheet = dataSheet,
    armor = 250,
    moveSpeed = 65,
    maxHealth = 20,
    itemData = {
      level = 1,
      dropRate = 20
    },
    experience = 1,
    w = spriteWidth,
    h = spriteHeight,
    animations = animations,
    abilities = {
      PelletShot
    },
    attackRange = attackRange,
    fillColor = fillColor,
    onDestroyStart = onDestroyStart
  }
end