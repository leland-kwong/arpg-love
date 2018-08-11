local Ai = require 'components.ai.ai'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local noop = require 'utils.noop'
local f = require 'utils.functional'
local config = require 'config'
local pprint = require 'utils.pprint'

local floor = math.floor

local SpawnerAi = {
  -- these need to be passed in
  grid = nil,
  WALKABLE = 0,

  colWorld = collisionWorlds.map,
  pxToGridUnits = function(screenX, screenY)
    local gridPixelX, gridPixelY = screenX, screenY
    local gridX, gridY =
      floor(gridPixelX / gridSize),
      floor(gridPixelY / gridSize)
    return gridX, gridY
  end,
  gridSize = config.gridSize,
  findNearestTarget = noop,
}

local function AiFactory(self, x, y, speed, scale)
  return Ai.create(
    x * self.gridSize, y * self.gridSize,
    speed,
    scale,
    self.colWorld,
    self.pxToGridUnits,
    self.findNearestTarget,
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

  self.ai = {
    AiFactory(
      self,
      3,
      3,
      150,
      1
    )
  }
end

function SpawnerAi.update(self, dt)
  -- f.forEach(self.ai, function(ai)
  --   ai:update(self.grid, self.flowField, dt)
  -- end)
end

function SpawnerAi.draw(self)
  f.forEach(self.ai, function(ai)
    ai:draw()
  end)
end

return groups.all.createFactory(function(defaults)
  SpawnerAi.drawOrder = function(self)
    return defaults.drawOrder(self) + 1
  end
  return SpawnerAi
end)
