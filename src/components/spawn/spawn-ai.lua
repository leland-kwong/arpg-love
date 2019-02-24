local Component = require 'modules.component'
local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local CollisionGroups = require 'modules.collision-groups'
local groups = require 'components.groups'
local config = require 'config.config'
local typeCheck = require 'utils.type-check'
local Math = require 'utils.math'
local animationFactory = require 'components.animation-factory'
local setProp = require 'utils.set-prop'
local aiTypes = require 'components.ai.types'
local Map = require 'modules.map-generator.index'
local f = require 'utils.functional'

local function getItemPositions(items)
  local binPack = require 'utils..bin-pack'
  local done = false
  local sizeIncrement = 16
  local width, height = 0, 0
  local tryCount = 0
  local newItems
  while (not done) do
    width, height = (tryCount + 1) * sizeIncrement,
      (tryCount + 1) * sizeIncrement
    newItems = {}
    local bp = binPack(width, height)
    local i = 1
    local tooSmall = false
    while (i <= #items) and (not tooSmall) do
      local item = items[i]
      local rect = bp:insert(item.w, item.h)
      if (not rect) then
        tooSmall = true
      else
        table.insert(newItems, rect)
      end
      i = i + 1
    end
    done = (not tooSmall)
    tryCount = tryCount + 1
  end

  return width, height, newItems
end

local spawnCollisionFilter = function(item, other)
  if CollisionGroups.matches(other.group, 'obstacle enemyAi') then
    return 'slide'
  end
  return false
end

local function repositionAiToPreventStacking(spawnedAi, x, y, collisionWorld)
  local width, height, positions = getItemPositions(spawnedAi)
  --[[
    check collisions using a bounding box around all ai to make sure
    they fit within the area
  ]]
  local boundingBox = {}
  collisionWorld:add(boundingBox, x, y, width, height)
  local spawnX, spawnY = collisionWorld:move(boundingBox, x, y, spawnCollisionFilter)
  collisionWorld:remove(boundingBox)
  for i=1, #positions do
    local ai = spawnedAi[i]
    local p = positions[i]
    ai:setPosition(
      p.x + spawnX,
      p.y + spawnY
    )
  end
end

local SpawnerAi = {
  -- debug = true,
  group = groups.firstLayer,
  x = 0,
  y = 0,
  moveSpeed = 0,
  -- these need to be passed in
  grid = nil,
  WALKABLE = Map.WALKABLE,

  colWorld = collisionWorlds.map,
  pxToGridUnits = require 'utils.position'.pixelsToGridUnits,
  gridSize = config.gridSize,
}
SpawnerAi.__index = SpawnerAi

local function AiFactory(props)
  local self = setmetatable(props, SpawnerAi)
  assert(
    type(self.target) == 'function',
    'target property must be a function'
  )
  assert(type(self.rarity) == 'function', 'a rarity function must be provided')

  local function findNearestTarget(otherX, otherY, otherSightRadius)
    if not self.target then
      return nil
    end
    local target = self.target()
    if (not target) then
      return nil
    end

    local tPosX, tPosY = target.x, target.y
    local dist = Math.dist(tPosX, tPosY, otherX, otherY)
    local withinVision = dist <= otherSightRadius

    if withinVision then
      return tPosX, tPosY
    end

    return nil
  end

  local spawnX, spawnY =
    self.x * self.gridSize,
    self.y * self.gridSize
  local spawnedAi = f.map(self.types, function(aiFactory)
    local aiDefinition = (type(aiFactory) == 'table') and
      aiFactory or
      aiTypes.typeDefs[aiFactory]
    local aiPrototype = aiDefinition.create()
    aiPrototype = setProp(aiPrototype)
    local props = self.rarity(aiPrototype)
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

  repositionAiToPreventStacking(spawnedAi, spawnX, spawnY, self.colWorld)

  return spawnedAi
end

return AiFactory
