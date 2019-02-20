local Component = require 'modules.component'
local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
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
  minDamage = 8,
  maxDamage = 12,
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
        damage = math.random(self.minDamage, self.maxDamage),
        source = self:getId()
      })
    end

    self:delete(true)
  end
})

local PunchAbility = {
  range = 1.5,
  actionSpeed = 1,
  cooldown = 0.3
}

function PunchAbility.use(self, state, targetX, targetY)
  state.targetX = targetX
  state.targetY = targetY
  state.isNewAttack = true
  local sound = love.audio.newSource('built/sounds/ROBOTIC_Servo_Medium_Mid-Movement_mono.wav', 'static')
  love.audio.play(sound)
end

-- returns [BOOLEAN] - status about whether ability is still animating
function PunchAbility.update(self, state, dt)
  local attackAnimation = self.animations.attacking
  if state.isNewAttack then
    state.hasHit = false
    attackAnimation:setFrame(1)
  end
  if (state.isNewAttack or state.isAnimating) then
    state.isNewAttack = false
    self:set(
      'animation',
      attackAnimation
    )
    local isLastFrame = attackAnimation:isLastFrame()
    local isHitFrame = attackAnimation.index == 4
    if isHitFrame and (not state.hasHit) then
      state.hasHit = true
      local attack = PunchAttack.create({
          x = self.x
        , y = self.y
        , x2 = state.targetX
        , y2 = state.targetY
        , w = 16
        , h = 16
        , targetGroup = collisionGroups.player
      })
    end
    state.isAnimating = (not isLastFrame)
    return state.isAnimating
  else
    self:set(
      'animation',
      self.animations.idle
    )
  end
  return false
end

local AiBlueprint = require 'components.ai.create-blueprint'
return AiBlueprint({
  baseProps = {
    type = 'ai-melee-bot',
  },
  create = function()
    local animations = {
      moving = animationFactory:new({
        'melee-bot/melee-bot-0',
        'melee-bot/melee-bot-1',
        'melee-bot/melee-bot-2',
        'melee-bot/melee-bot-3',
        'melee-bot/melee-bot-4',
        'melee-bot/melee-bot-5',
        'melee-bot/melee-bot-6',
      }):setDuration(PunchAbility.actionSpeed),
      idle = animationFactory:new({
        'melee-bot/melee-bot-7',
        'melee-bot/melee-bot-8',
        'melee-bot/melee-bot-9',
        'melee-bot/melee-bot-10',
      }):setDuration(1),
      attacking = animationFactory:new({
        'melee-bot/melee-bot-11',
        'melee-bot/melee-bot-12',
        'melee-bot/melee-bot-13',
        -- hit frame
        'melee-bot/melee-bot-14',
        'melee-bot/melee-bot-14',
        -- recovery frames
        'melee-bot/melee-bot-13',
        'melee-bot/melee-bot-12',
      }):setDuration(PunchAbility.actionSpeed)
    }

    local attackRange = 1.5
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
      moveSpeed = 95,
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
        PunchAbility
      },
      attackRange = attackRange,
      fillColor = fillColor,
      onDestroyStart = onDestroyStart
    }
  end
})