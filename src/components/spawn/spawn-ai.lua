local Component = require 'modules.component'
local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local config = require 'config.config'
local typeCheck = require 'utils.type-check'
local Math = require 'utils.math'
local animationFactory = require 'components.animation-factory'
local setProp = require 'utils.set-prop'
local aiTypes = require 'components.ai.types'
local aiRarity = require 'components.ai.rarity'
local f = require 'utils.functional'

local SpawnerAi = {
  debug = true,
  group = groups.firstLayer,
  x = 0,
  y = 0,
  moveSpeed = 0,
  rarity = aiRarity, -- [FUNCTION]
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
SpawnerAi.__index = SpawnerAi

local directions = {
  1, -1
}
local function getRandomDirection()
  return directions[math.random(1, 2)]
end

local function AiFactory(props)
  local self = setmetatable(props, SpawnerAi)
  assert(
    type(self.target) == 'function',
    'target property must be a function'
  )

  local function findNearestTarget(otherX, otherY, otherSightRadius)
    if not self.target then
      return nil
    end
    local target = self.target()
    local tPosX, tPosY = target.x, target.y
    local dist = Math.dist(tPosX, tPosY, otherX, otherY)
    local withinVision = dist <= otherSightRadius

    if withinVision then
      return tPosX, tPosY
    end

    return nil
  end

  return f.map(self.types, function(aiType)
    local aiPrototype
    if (type(aiType) == 'function') then
      aiPrototype = setProp(aiType())
    else
      aiPrototype = setProp(aiTypes.typeDefs[aiType]())
    end
    local spawnX, spawnY =
      self.x * self.gridSize + math.random(0, self.gridSize) * getRandomDirection(),
      self.y * self.gridSize + math.random(0, self.gridSize) * getRandomDirection()
    local props = self.rarity(aiPrototype)
      :set('debug',             self.debug)
      :set('x',                 spawnX)
      :set('y',                 spawnY)
      :set('collisionWorld',    self.colWorld)
      :set('pxToGridUnits',     self.pxToGridUnits)
      :set('findNearestTarget', aiPrototype.findNearestTarget or findNearestTarget)
      :set('grid',              self.grid)
      :set('gridSize',          self.gridSize)
      :set('WALKABLE',          self.WALKABLE)
      :set('showAiPath',        self.showAiPath)
    local ai = Ai.create(props):setParent(
      Component.get('MAIN_SCENE')
    )
    return ai
  end)
end

return AiFactory
