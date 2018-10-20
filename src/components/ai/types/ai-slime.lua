local Component = require 'modules.component'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionGroups = require 'modules.collision-groups'

local function slimeAttackCollisionFilter(item)
  return collisionGroups.matches(item.group, collisionGroups.player)
end

local SlimeAttack = Component.createFactory({
  group = groups.all,
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
      slimeAttackCollisionFilter
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

local function onDestroyStart()
  local Sound = require 'components.sound'
  love.audio.play(Sound.functions.creatureDestroyed())
end

local DashAbility = {
  range = 6,
  attackTime = 0.2,
  cooldown = 1
}

function DashAbility.use(self)
  local Dash = require 'components.abilities.dash'
  local projectile = Dash.create({
      fromCaster = self
    , duration = 7/60
  })
  return skill
end

local SlimeSlap =  {
  range = 3,
  attackTime = 0.4,
  cooldown = 0.5
}

function SlimeSlap.use(self, state, targetX, targetY)
  state.isNewAttack = true
  local attack = SlimeAttack.create({
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

function SlimeSlap.update(self, state, dt)
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

local Chance = require 'utils.chance'
local Color = require 'modules.color'
local getRandomProps = Chance({
  -- halloween style
  {
    chance = 5,
    __call = function()
      return {
        color = {Color.rgba255(249, 157, 37)},
        name = 'jack-o-slime-o'
      }
    end
  },
  {
    chance = 1,
    __call = function()
      return {
        -- green
        color = {0,1,0.2,1},
        name = 'slime'
      }
    end
  }
})

return function()
  local animations = {
    attacking = animationFactory:new({
      'slime/slime1',
      'slime/slime2',
      'slime/slime3',
      'slime/slime4',
      'slime/slime5',
      'slime/slime6',
      'slime/slime7',
      'slime/slime8',
      'slime/slime9',
      'slime/slime10',
      'slime/slime11',
    }),
    idle = animationFactory:new({
      'slime/slime12',
      'slime/slime13',
      'slime/slime14',
      'slime/slime15',
      'slime/slime16'
    }),
    moving = animationFactory:new({
      'slime/slime12',
      'slime/slime13',
      'slime/slime14',
      'slime/slime15',
      'slime/slime16'
    })
  }

  local attackRange = 3
  local spriteWidth, spriteHeight = animations.idle:getSourceSize()

  local randomProps = getRandomProps()
  local dataSheet = {
    name = randomProps.name,
    properties = {
      'melee',
      'dashes in when near'
    }
  }

  return {
    modifierNames = {},
    itemData = {
      level = 2,
      dropRate = 30
    },
    dataSheet = dataSheet,
    moveSpeed = 105,
    maxHealth = 25,
    w = spriteWidth,
    h = spriteHeight,
    flatPhysicalReduction = 1,
    animations = animations,
    abilities = {
      DashAbility,
      SlimeSlap,
    },
    armor = 900,
    experience = 2,
    attackRange = attackRange,
    fillColor = randomProps.color,
    onDestroyStart = onDestroyStart
  }
end