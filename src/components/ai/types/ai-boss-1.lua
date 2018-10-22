local AiEyeball = require 'components.ai.types.ai-eyeball'
local collisionGroups = require 'modules.collision-groups'
local debounce = require 'modules.debounce'
local animationFactory = require 'components.animation-factory'
local itemConfig = require(require('alias').path.items..'.config')
local Component = require 'modules.component'

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

local MultiShot = {
  range = 14,
  attackTime = 0.5,
  cooldown = 0.4
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

local SpawnMinions = {
  range = 40,
  attackTime = 1,
  cooldown = 3
}

Component.newGroup({
  name = 'boss1Minions'
})

local function countMinions()
  local count = 0
  for _ in pairs(Component.groups.boss1Minions.getAll()) do
    count = count + 1
  end
  return count
end

local minionWarpTime = 1.5

local function fadeInMinions()
  for _,minion in pairs(Component.groups.boss1Minions.getAll()) do
    local colorIncrement = 1/60/minionWarpTime
    if minion.outlineColor then
      minion.outlineColor[4] = math.min(1, minion.outlineColor[4] + colorIncrement)
    end
    minion.fillColor[4] = math.min(1, minion.fillColor[4] + colorIncrement)
    local isFadedIn = minion.fillColor[4] == 1
    if isFadedIn then
      minion.silenced = false
      minion.invulnerable = false
      minion.outlineColor = minion.rarityColor
    end
  end
end

function SpawnMinions.use(_, state)
  state.isNewSpawn = true
  state.clock = 0
  state.minions = state.minions or {}
end

function SpawnMinions.update(_, state, dt)
  fadeInMinions()
  local minionCount = countMinions()
  local maxNumMinions = 12
  if state.isNewSpawn and (minionCount < maxNumMinions) then
    if (state.clock == 0) then
      local Spawn = require 'components.spawn.spawn-ai'
      local minionType = require 'components.ai.types'.types.MELEE_BOT
      local playerRef = Component.get('PLAYER')
      local config = require 'config.config'
      local minions = Spawn({
        grid = Component.get('MAIN_SCENE').mapGrid,
        WALKABLE = require 'modules.map-generator.index'.WALKABLE,
        target = function()
          return playerRef
        end,
        x = playerRef.x / config.gridSize,
        y = playerRef.y / config.gridSize - 4,
        types = {
          minionType,
          minionType,
          minionType
        }
      })
      love.audio.play(
        love.audio.newSource('built/sounds/warped-in.wav', 'static')
      )
      for i=1, #minions do
        local m = minions[i]
        m.itemData.dropRate = 0
        m.sightRadius = 25
        m.experience = 0
        m.silenced = true
        local Color = require 'modules.color'
        m.outlineColor = {Color.multiplyAlpha(Color.SKY_BLUE, 0.4)}
        m.fillColor = {Color.multiplyAlpha(Color.WHITE, 0)}
        local msgBus = require 'components.msg-bus'
        msgBus.send(msgBus.CHARACTER_HIT, {
          parent = m,
          damage = 0,
          duration = minionWarpTime,
          modifiers = {
            moveSpeed = -400,
          },
          source = 'BOSS_WARPED_IN'
        })
        m.invulnerable = true
        Component.addToGroup(m, 'boss1Minions')
      end
    end
    state.clock = state.clock + dt
    local isReady = state.clock > SpawnMinions.attackTime
    return (not isReady)
  end
  return false
end

return function(props)
  local aiProps = AiEyeball()
  aiProps.lightRadius = 40
  aiProps.sightRadius = 20
  local Color = require 'modules.color'
  aiProps.lightColor = Color.SKY_BLUE
  aiProps.attackRange = 12
  aiProps.maxHealth = 500

  local animations = {
    idle = animationFactory:new({
      'boss-1/boss-1'
    }),
    moving = animationFactory:new({
      'boss-1/boss-1'
    })
  }
  local spriteWidth, spriteHeight = animations.idle:getSourceSize()
  aiProps.itemData.minRarity = itemConfig.rarity.RARE
  aiProps.itemData.maxRarity = itemConfig.rarity.RARE

  aiProps.animations = animations
  aiProps.w = spriteWidth
  aiProps.h = spriteHeight
  aiProps.dataSheet = {
    name = 'Erion, Guardian of Aureus',
    properties = {
      'ranged',
      'slow-on-hit',
      'multi-shot'
    }
  }
  table.insert(aiProps.abilities, SpawnMinions)
  table.insert(aiProps.abilities, MultiShot)
  return aiProps
end