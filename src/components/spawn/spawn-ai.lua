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
  'MINI_BOT',
  -- 'EYEBALL'
})

local aiTypeDef = {
  [aiType.SLIME] = require 'components.spawn.ai-slime',
  [aiType.MINI_BOT] = require 'components.spawn.ai-mini-bot',
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
