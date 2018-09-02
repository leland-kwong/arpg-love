local Component = require 'modules.component'
local config = require 'config.config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Position = require 'utils.position'
local Color = require 'modules.color'
local memoize = require 'utils.memoize'
local typeCheck = require 'utils.type-check'
local random = math.random
local tween = require 'modules.tween'

local colMap = collisionWorlds.map

local defaultFilters = {
  obstacle = true,
  obstacle2 = true,
}

local ColFilter = memoize(function(groupToMatch)
  return function (item, other)
    if (other.group ~= groupToMatch) and not defaultFilters[other.group] then
      return false
    end
    return 'touch'
  end
end)

local ChainLightning = {
  group = groups.all,

  -- [DEFAULTS]

  -- start position
  x = 0,
  y = 0,
  w = 16,
  h = 16,

  -- target position
  x2 = 0,
  y2 = 0,
  minDamage = 1,
  maxDamage = 2,
  weaponDamageScaling = 1,
  startOffset = 0,
  scale = 1,
  lifeTime = 5,
  speed = 200,
  cooldown = 0.4,
  maxTargets = 3,
  targetGroup = nil,
  color = {Color.rgba255(0, 246, 255, 1)}
}

local function findNearestTarget(self, foundTargets)
  local maxSeekRadius = 10 -- radius to find nearest targets
  local nearestEnemyFound = nil
  local i = 2
  while (i < maxSeekRadius) and (not nearestEnemyFound) do
    local seekRadius = i * config.gridSize
    local width, height = seekRadius * 2, seekRadius * 2
    local collisionX, collisionY = self.x, self.y
    local items, len = collisionWorlds.map:queryRect(
      collisionX - width/2,
      collisionY - height/2,
      width,
      height,
      function(item)
        if (not nearestEnemyFound) and item.group == 'ai' then
          local target = item.parent
          local isAlreadyFound = foundTargets:hasTarget(target)
          if not isAlreadyFound then
            nearestEnemyFound = target
          end
        end
        return false
      end
    )
    i = i + 1
  end

  return nearestEnemyFound
end

local function hasTarget(self, target)
  local found = false
  local i = 1
  while (i <= #self) and (not found) do
    local t = self[i]
    found = target == t
    i = i + 1
  end
  return found
end

ChainLightning.init = function(self)
  assert(
    type(self.targetGroup) == 'string' and self.targetGroup ~= nil,
    '[ChainLightning] `targetGroup` is required'
  )

  -- find 3 targets to hit ahead of time
  self.targets = {
    hasTarget = hasTarget
  }
  for i=1, self.maxTargets do
    local target = findNearestTarget(self, self.targets)
    table.insert(self.targets, target)
  end
end

ChainLightning.update = function(self, dt)
  self.lifeTime = self.lifeTime - dt

  local isExpired = self.lifeTime <= 0
  if isExpired then
    self:delete()
  end
end

local function drawTargets(self)
  local previousTarget = nil
  for i=1, #self.targets do
    local t = self.targets[i]

    if previousTarget then
      love.graphics.setColor(1,1,1,1)
      love.graphics.setLineWidth(2)
      love.graphics.line(
        previousTarget.x,
        previousTarget.y,
        t.x,
        t.y
      )
    end

    previousTarget = t

    love.graphics.setColor(1,1,1,1)
    love.graphics.circle(
      'fill',
      t.x,
      t.y,
      5
    )
  end
end

ChainLightning.draw = function(self)
  local originalLineWidth = love.graphics.getLineWidth()
  drawTargets(self)
  love.graphics.setLineWidth(originalLineWidth)
end

ChainLightning.drawOrder = function(self)
  local order = self.group.drawOrder(self) + 100
  return order
end

return Component.createFactory(ChainLightning)