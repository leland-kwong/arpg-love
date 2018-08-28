local Component = require 'modules.component'
local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local config = require 'config.config'
local typeCheck = require 'utils.type-check'
local Math = require 'utils.math'

local floor = math.floor

local SpawnerAi = {
  group = groups.all,
  x = 0,
  y = 0,
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
      floor(gridPixelX / gridSize),
      floor(gridPixelY / gridSize)
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

  return Ai.create({
    x = self.x * self.gridSize,
    y = self.y * self.gridSize,
    speed = self.speed,
    scale = self.scale,
    collisionWorld = self.colWorld,
    pxToGridUnits = self.pxToGridUnits,
    findNearestTarget = findNearestTarget,
    grid = self.grid,
    gridSize = self.gridSize,
    WALKABLE = self.WALKABLE,
    showAiPath = self.showAiPath,
    attackRange = self.attackRange,
    COLOR_FILL = self.COLOR_FILL
  })
end

function SpawnerAi.init(self)
  msgBus.subscribe(function(msgType, msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    if msgBus.NEW_FLOWFIELD == msgType then
      self.flowField = msgValue.flowField
    end
  end)

  self.ai = AiFactory(self):setParent(self)
end

function SpawnerAi.update(self, dt)
  if self.ai:isDeleted() then
    self:delete()
    return
  end
  self.ai._update2(self.ai, self.grid, self.flowField, dt)
end

return Component.createFactory(SpawnerAi)
