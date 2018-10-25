local Component = require 'modules.component'
local AiEyeball = require 'components.ai.types.ai-eyeball'
local collisionGroups = require 'modules.collision-groups'
local debounce = require 'modules.debounce'
local animationFactory = require 'components.animation-factory'
local itemConfig = require(require('alias').path.items..'.config')

local playFrostShotSound = debounce(function()
  local Sound = require 'components.sound'
  local source = Sound.FROST_SHOT
  source:setFilter(frostShotSoundFilter)
  source:setVolume(0.4)
  love.audio.stop(source)
  love.audio.play(source)
end, 0.5)

local function Attack(self, x2, y2)
  local FrostSpark = require 'components.abilities.frost-spark'

  FrostSpark.create({
      debug = false
    , x = self.x
    , y = self.y - self.z
    , x2 = x2
    , y2 = y2
    , speed = 115
    , lifeTime = 2.5
    , targetGroup = collisionGroups.player
    , minDamage = 1
    , maxDamage = 2
    , drawOrder = function()
      return self.drawOrder(self) + 1
    end
  })
end

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

local MultiShot = {
  range = 14,
  attackTime = 0.4,
  cooldown = 1
}

function MultiShot.use(self, state, targetX, targetY)
  Attack(self, targetX, targetY)

  local Position = require 'utils.position'
  local dx, dy = Position.getDirection(self.x, self.y, targetX, targetY)
  local startAngle = math.atan2(dx, dy)
  local length = 5
  local newAngle = math.pi/8
  local finalAngle1 = (startAngle + newAngle)
  local x3, y3 = self.x + length * math.sin(finalAngle1), self.y + length * math.cos(finalAngle1) - self.z
  Attack(self, x3, y3)

  local finalAngle2 = (startAngle - newAngle)
  local x4, y4 = self.x + length * math.sin(finalAngle2), self.y + length * math.cos(finalAngle2) - self.z
  Attack(self, x4, y4)

  playFrostShotSound()

  state.isNewAttack = true
  state.clock = 0

  return skill
end

function MultiShot.update(_, state, dt)
  if state.isNewAttack then
    state.clock = state.clock + dt
    local isAbilityComplete = state.clock >= MultiShot.attackTime
    if isAbilityComplete then
      state.isNewAttack = false
    end
    return (not isAbilityComplete)
  end
  return false
end

return function(props)
  local aiProps = AiEyeball()

  local animations = {
    attacking = animationFactory:new({
      'ai-legendaries/legendary-1/legendary-ai-1',
      'ai-legendaries/legendary-1/legendary-ai-1'
    }):setDuration(MultiShot.attackTime),
    idle = animationFactory:new({
      'ai-legendaries/legendary-1/legendary-ai-1'
    }),
    moving = animationFactory:new({
      'ai-legendaries/legendary-1/legendary-ai-1'
    })
  }
  local spriteWidth, spriteHeight = animations.idle:getSourceSize()
  aiProps.itemData.minRarity = itemConfig.rarity.NORMAL
  aiProps.itemData.maxRarity = itemConfig.rarity.RARE
  aiProps.itemData.dropRate = aiProps.itemData.dropRate * 30
  aiProps.maxHealth = aiProps.maxHealth * 8

  aiProps.animations = animations
  aiProps.w = spriteWidth
  aiProps.h = spriteHeight
  aiProps.dataSheet = {
    name = 'r-19 the mad',
    properties = {
      'ranged',
      'slow-on-hit',
      'multi-shot'
    }
  }
  table.insert(aiProps.abilities, MultiShot)
  return aiProps
end