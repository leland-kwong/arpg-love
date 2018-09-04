local Component = require 'modules.component'
local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local config = require 'config.config'
local typeCheck = require 'utils.type-check'
local Math = require 'utils.math'
local animationFactory = require 'components.animation-factory'
local Enum = require 'utils.enum'

local aiType = Enum({
  'MELEE',
  'RANGE',
  'EYEBALL'
})

local aiTypeDef = {
  [aiType.MELEE] = function()
    local animations = {
      attacking = animationFactory:new({
        'slime1',
        'slime2',
        'slime3',
        'slime4',
        'slime5',
        'slime6',
        'slime7',
        'slime8',
        'slime9',
        'slime10',
        'slime11',
      }),
      idle = animationFactory:new({
        'slime12',
        'slime13',
        'slime14',
        'slime15',
        'slime16'
      }),
      moving = animationFactory:new({
        'slime12',
        'slime13',
        'slime14',
        'slime15',
        'slime16'
      })
    }

    local function slimeAttackCollisionFilter(item)
      return item.group == 'player'
    end

    local SlimeAttack = Component.createFactory({
      group = groups.all,
      minDamage = 5,
      maxDamage = 10,
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

    local ability1 = (function()
      local curCooldown = 0
      local initialCooldown = 0
      local skill = {}
      local isAnimationComplete = false

      function skill.use(self, targetX, targetY)
        if curCooldown > 0 then
          return skill
        else
          local attack = SlimeAttack.create({
              x = self.x
            , y = self.y
            , x2 = targetX
            , y2 = targetY
            , w = 64
            , h = 36
            , cooldown = 0.5
            , targetGroup = 'player'
          })
          curCooldown = attack.cooldown
          initialCooldown = attack.cooldown
          return skill
        end
      end

      function skill.updateCooldown(self, dt)
        local isNewAttack = curCooldown == initialCooldown
        local attackAnimation = animations.attacking
        if isNewAttack then
          isAnimationComplete = false
        end
        self:set(
          'animation',
          attackAnimation
        )
        if not isAnimationComplete then
          local animation, isLastFrame = attackAnimation:update(dt/2)
          isAnimationComplete = isLastFrame
        end

        curCooldown = curCooldown - dt
        return skill
      end

      return skill
    end)()

    local attackRange = 3
    local fillColor = {0,1,0.2}
    local spriteWidth, spriteHeight = animations.idle:getSourceSize()

    return spriteWidth,
      spriteHeight,
      animations,
      ability1,
      attackRange,
      fillColor
  end,
  [aiType.RANGE] = function()
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

    return spriteWidth, spriteHeight, animations, ability1, attackRange
  end
}

local SpawnerAi = {
  group = groups.all,
  x = 0,
  y = 0,
  types = aiType,
  speed = 0,
  scale = 1,
  -- these need to be passed in
  grid = nil,
  WALKABLE = nil,

  colWorld = collisionWorlds.map,
  pxToGridUnits = function(screenX, screenY, gridSize)
    typeCheck.validate(gridSize, typeCheck.NUMBER)

    local gridPixelX, gridPixelY = screenX, screenY
    local gridX, gridY =
      Math.round(gridPixelX / gridSize),
      Math.round(gridPixelY / gridSize)
    return gridX, gridY
  end,
  gridSize = config.gridSize,
}

local function AiFactory(self, x, y, speed, scale)

  local function findNearestTarget(otherX, otherY, otherSightRadius)
    if not self.target then
      return nil
    end

    local tPosX, tPosY = self.target:getPosition()
    local dist = Math.dist(tPosX, tPosY, otherX, otherY)
    local withinVision = dist <= otherSightRadius

    if withinVision then
      return tPosX, tPosY
    end

    return nil
  end

  -- local type = math.random(0, 1) == 1 and aiType.MELEE or aiType.RANGE
  local w, h, animations, ability1, attackRange, fillColor = aiTypeDef[self.type]()

  return Ai.create({
    debug = self.debug,
    x = self.x * self.gridSize,
    y = self.y * self.gridSize,
    w = w,
    h = h,
    speed = self.speed,
    scale = 1,
    collisionWorld = self.colWorld,
    pxToGridUnits = self.pxToGridUnits,
    findNearestTarget = findNearestTarget,
    grid = self.grid,
    gridSize = self.gridSize,
    WALKABLE = self.WALKABLE,
    showAiPath = self.showAiPath,
    attackRange = attackRange,
    COLOR_FILL = fillColor,
    animations = animations,
    ability1 = ability1
  })
end

function SpawnerAi.init(self)
  self.ai = AiFactory(self):setParent(self)
end

function SpawnerAi.update(self, dt)
  if self.ai:isDeleted() then
    self:delete()
    return
  end
  self.ai._update2(self.ai, self.grid, dt)
end

return Component.createFactory(SpawnerAi)
