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
local setProp = require 'utils.set-prop'

local aiType = Enum({
  'SLIME',
  'RANGE',
  -- 'EYEBALL'
})

local aiTypeDef = {
  [aiType.SLIME] = require 'components.spawn.ai-slime',
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

    return {
      speed = 80,
      w = spriteWidth,
      h = spriteHeight,
      animations = animations,
      ability1 = ability1,
      attackRange = attackRange,
      fillColor = fillColor
    }
  end,
  -- [aiType.EYEBALL] = require 'components.spawn.ai-eyeball'
}

local SpawnerAi = {
  -- debug = true,
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
  local aiPrototype = setProp(aiTypeDef[self.type]())
  return Ai.create(aiPrototype
    :set('debug',             self.debug)
    :set('x',                 self.x * self.gridSize)
    :set('y',                 self.y * self.gridSize)
    :set('scale',             1)
    :set('collisionWorld',    self.colWorld)
    :set('pxToGridUnits',     self.pxToGridUnits)
    :set('findNearestTarget', findNearestTarget)
    :set('grid',              self.grid)
    :set('gridSize',          self.gridSize)
    :set('WALKABLE',          self.WALKABLE)
    :set('showAiPath',        self.showAiPath)
  )
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
