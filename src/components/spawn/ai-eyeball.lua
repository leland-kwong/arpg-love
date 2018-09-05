local animationFactory = require 'components.animation-factory'

local function eyeballAttackCollisionFilter(item)
  return item.group == 'player'
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

  -- deals damage with a chance to slow
  local ability1 = (function()
    local curCooldown = 0
    local skill = {}

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
          , cooldown = 0.3
          , targetGroup = 'player'
        })
        curCooldown = projectile.cooldown
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

  return {
    speed = 100,
    maxHealth = 17,
    w = spriteWidth,
    h = spriteHeight,
    animations = animations,
    ability1 = ability1,
    attackRange = attackRange
  }
end