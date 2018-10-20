local Component = require 'modules.component'
local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'
local collisionGroups = require 'modules.collision-groups'

local function onDestroyStart()
  local Sound = require 'components.sound'
  love.audio.play(Sound.functions.robotDestroyed())
end

local function punchAttackCollisionFilter(item)
  return collisionGroups.matches(item.group, collisionGroups.player)
end

local PunchAttack = Component.createFactory({
  group = Component.groups.all,
  minDamage = 5,
  maxDamage = 10,
  itemLevel = 1,
  attackTime = 0.2,
  init = function(self)
    local items, len = collisionWorlds.map:queryRect(
      self.x2 - self.w/2,
      self.y2,
      self.w,
      self.h,
      punchAttackCollisionFilter
    )

    for i=1, len do
      local it = items[i]
      msgBus.send(msgBus.CHARACTER_HIT, {
        parent = it.parent,
        damage = math.random(self.minDamage, self.maxDamage)
      })
    end

    self:delete(true)
  end
})

function PunchAttack.use(self, state, targetX, targetY)
  state.isNewAttack = true
  local attack = PunchAttack.create({
      x = self.x
    , y = self.y
    , x2 = targetX
    , y2 = targetY
    , w = 64
    , h = 36
    , targetGroup = collisionGroups.player
  })

  local Sound = require 'components.sound'
  love.audio.stop(Sound.SLIME_SPLAT)
  love.audio.play(Sound.SLIME_SPLAT)
  return skill
end

function PunchAttack.update(self, state, dt)
  local isNewAttack = curCooldown == initialCooldown
  local attackAnimation = self.animations.attacking
  if state.isNewAttack then
    state.isNewAttack = false
    state.isAnimationComplete = false
    attackAnimation:setFrame(1)
  end
  if (not state.isAnimationComplete) then
    self:set(
      'animation',
      attackAnimation
    )
    local animation, isLastFrame = attackAnimation:update(dt/2)
    state.isAnimationComplete = isLastFrame
  else
    self:set(
      'animation',
      self.animations.idle
    )
  end
  return skill
end

return function()
  local animations = {
    moving = animationFactory:new({
      'melee-bot/melee-bot-0',
      'melee-bot/melee-bot-1',
      'melee-bot/melee-bot-2',
      'melee-bot/melee-bot-3',
      'melee-bot/melee-bot-4',
      'melee-bot/melee-bot-5',
      'melee-bot/melee-bot-6',
    }),
    idle = animationFactory:new({
      'melee-bot/melee-bot-7',
      'melee-bot/melee-bot-8',
      'melee-bot/melee-bot-9',
      'melee-bot/melee-bot-10',
    }),
    attacking = animationFactory:new({
      'melee-bot/melee-bot-11',
      'melee-bot/melee-bot-12',
      'melee-bot/melee-bot-13',
      'melee-bot/melee-bot-14',
    })
  }

  local attackRange = 8
  local spriteWidth, spriteHeight = animations.idle:getSourceSize()
  local dataSheet = {
    name = 'punch-bot',
    properties = {
      'melee'
    }
  }

  return {
    dataSheet = dataSheet,
    armor = 250,
    moveSpeed = 120,
    maxHealth = 20,
    itemData = {
      level = 1,
      dropRate = 10
    },
    experience = 1,
    w = spriteWidth,
    h = spriteHeight,
    animations = animations,
    abilities = {
      -- PunchAttack
    },
    attackRange = attackRange,
    fillColor = fillColor,
    onDestroyStart = onDestroyStart
  }
end