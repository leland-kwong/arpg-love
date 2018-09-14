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
local aiTypes = require 'components.spawn.ai-types'
local aiRarity = require 'components.spawn.ai-rarity'
local f = require 'utils.functional'

local SpawnerAi = {
  -- debug = true,
  group = groups.firstLayer,
  x = 0,
  y = 0,
  moveSpeed = 0,
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

local directions = {
  1, -1
}
local function getRandomDirection()
  return directions[math.random(1, 2)]
end

local function AiFactory(self, x, y, moveSpeed, scale)

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

  return f.map(self.types, function(aiType)
    local aiPrototype = setProp(aiTypes.typeDefs[aiType]())
    local spawnX, spawnY =
      self.x * self.gridSize + math.random(0, self.gridSize) * getRandomDirection(),
      self.y * self.gridSize + math.random(0, self.gridSize) * getRandomDirection()
    return Ai.create(
      aiRarity(aiPrototype)
        :set('x',                 spawnX)
        :set('y',                 spawnY)
        :set('collisionWorld',    self.colWorld)
        :set('pxToGridUnits',     self.pxToGridUnits)
        :set('findNearestTarget', findNearestTarget)
        :set('grid',              self.grid)
        :set('gridSize',          self.gridSize)
        :set('WALKABLE',          self.WALKABLE)
        :set('showAiPath',        self.showAiPath)
    ):setParent(self)
  end)
end

function SpawnerAi.init(self)
  self.allAis = AiFactory(self)
end

function SpawnerAi.update(self, dt)
  local i = 1
  while i <= #self.allAis do
    local ai = self.allAis[i]
    if ai:isDeleted() then
      table.remove(self.allAis, i)
    else
      ai._update2(ai, self.grid, dt)
      i = i + 1
    end
  end
  if #self.allAis == 0 then
    self:delete(true)
  end
end

return Component.createFactory(SpawnerAi)
