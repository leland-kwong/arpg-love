local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'

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

return function()
  local animations = {
    moving = animationFactory:new({
      'ai-1',
      'ai-2',
      'ai-3',
      'ai-4',
      'ai-5',
      'ai-6',
    }),
    idle = animationFactory:new({
      'ai-7',
      'ai-8',
      'ai-9',
      'ai-10'
    })
  }

  local ability1 = (function()
    local curCooldown = 0
    local skill = {
      range = 8
    }

    function skill.use(self, targetX, targetY)
      if curCooldown > 0 then
        return skill
      else
        local Attack = require 'components.abilities.bullet'
        local projectile = Attack.create({
            debug = false
          , x = self.x
          , y = self.y
          , x2 = targetX
          , y2 = targetY
          , speed = 125
          , cooldown = 0.4
          , targetGroup = 'player'
        })
        curCooldown = projectile.cooldown
        playblasterSound()

        return skill
      end
    end

    function skill.updateCooldown(self, dt)
      curCooldown = curCooldown - dt
      return skill
    end

    return skill
  end)()

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
    moveSpeed = 80,
    maxHealth = 20,
    experience = 1,
    w = spriteWidth,
    h = spriteHeight,
    animations = animations,
    abilities = {
      ability1
    },
    attackRange = attackRange,
    fillColor = fillColor,
    onDestroyStart = onDestroyStart
  }
end