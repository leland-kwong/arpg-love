local Component = require 'modules.component'
local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local config = require 'config'
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

  return Ai.create(
    self.x * self.gridSize,
    self.y * self.gridSize,
    self.speed,
    self.scale,
    self.colWorld,
    self.pxToGridUnits,
    findNearestTarget,
    self.grid,
    self.gridSize,
    self.WALKABLE,
    self.showAiPath
  )
end

function SpawnerAi.init(self)
  msgBus.subscribe(function(msgType, msgValue)
    if msgBus.NEW_FLOWFIELD == msgType then
      self.flowField = msgValue.flowField
    end
  end)

  self.ai = AiFactory(self)
end

function SpawnerAi.update(self, dt)
  self.ai:update(self.grid, self.flowField, dt)
  self:setPosition(self.ai.x, self.ai.y)

  if self.ai.deleted then
    self:delete()
  end
end

function SpawnerAi.draw(self)
  self.ai:draw()
end

SpawnerAi.drawOrder = function(self)
  return self.group.drawOrder(self) + 1
end

return Component.createFactory(SpawnerAi)
