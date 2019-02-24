local Component = require 'modules.component'
local animationFactory = require 'components.animation-factory'
local debounce = require 'modules.debounce'
local collisionGroups = require 'modules.collision-groups'
local abs = math.abs

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
  actionSpeed = 0.3,
  cooldown = 1
}

local DissipateEffectBlueprint = {
  opacity = 1,
  radiusScale = 0.3,
  maxRadiusScale = 1
}

function DissipateEffectBlueprint.init(self)
  Component.addToGroup(self, 'all')
  self.animation = animationFactory:newStaticSprite('nova')
end

function DissipateEffectBlueprint.update(self, dt)
  self.opacity = self.opacity - dt * 2
  self.radiusScale = math.min(0.5, self.radiusScale + dt * 2)
  if self.opacity <= 0 then
    self:delete()
  end
end

function DissipateEffectBlueprint.draw(self)
  love.graphics.setColor(1,1,1,self.opacity)
  local ox, oy = self.animation:getOffset()
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    0,
    0.2 * self.radiusScale,
    0.3 * self.radiusScale,
    ox,
    oy
  )
end

local DissipateEffect = Component.createFactory(DissipateEffectBlueprint)

function FrostShot.use(_, state, targetX, targetY)
  state.targetX = targetX
  state.targetY = targetY
  state.isNewAttack = true
end

function FrostShot.update(self, state)
  local attackAnimation = self.animations.attacking
  if state.isNewAttack then
    state.abilityUsed = false
    attackAnimation:setFrame(1)
  end
  if (state.isNewAttack or state.isAnimating) then
    state.isNewAttack = false
    self:set(
      'animation',
      attackAnimation
    )
    local isLastFrame = attackAnimation:isLastFrame()
    local isHitFrame = attackAnimation.index == 2
    if isHitFrame and (not state.abilityUsed) then
      state.abilityUsed = true
      local Attack = require 'components.abilities.frost-spark'
      local projectile = Attack.create({
          debug = false
        , x = self.x
        , y = self.y - self.z
        , x2 = state.targetX
        , y2 = state.targetY
        , speed = 115
        , lifeTime = 60
        , targetGroup = collisionGroups.player
        , minDamage = 9
        , maxDamage = 12
      })
      playFrostShotSound()
      DissipateEffect.create({
        x = self.x + 4 * self.facingDirectionX,
        y = self.y - self.z,
        drawOrder = function()
          return self:drawOrder() + 1
        end
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
end

local heightChange = 2
local mt = {
  type = 'ai-eyeball',
  -- debug = true,
  scale = 1,
  z = 10,
  heightOffset = math.random(0, heightChange),
  heightChange = heightChange,
  moveSpeed = 85,
  maxHealth = 17,
  experience = 1,
  armor = 250,
  attackRange = 10,
  onUpdateStart = function(self, dt)
    self.heightOffset = self.heightOffset + (dt * self.heightChange)
    if self.heightOffset >= 4 then
      self.heightChange = abs(self.heightChange) * -1
    end
    if self.heightOffset <= 0 then
      self.heightChange = abs(self.heightChange)
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

local AiBlueprint = require 'components.ai.create-blueprint'
return AiBlueprint({
  baseProps = mt,
  create = function()
    local animations = {
      attacking = animationFactory:new({
        'eyeball/eyeball',
        'eyeball/eyeball',
      }):setDuration(FrostShot.actionSpeed),
      idle = animationFactory:new({
        'eyeball/eyeball'
      }),
      moving = animationFactory:new({
        'eyeball/eyeball'
      })
    }

    local spriteWidth, spriteHeight = animations.idle:getSourceSize()

    return {
      itemData = {
        level = 1,
        dropRate = 20
      },
      dataSheet = {
        name = 'i-229',
        properties = {
          'ranged',
          'slow on hit'
        }
      },
      w = spriteWidth,
      h = spriteHeight,
      animations = animations,
      abilities = {
        FrostShot
      },
    }
  end
})