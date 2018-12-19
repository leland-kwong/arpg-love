local Component = require 'modules.component'
local memoize = require 'utils.memoize'
local config = require 'config.config'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local CollisionGroups = require 'modules.collision-groups'
local gameWorld = require 'components.game-world'
local Position = require 'utils.position'
local Color = require 'modules.color'
local camera = require 'components.camera'
local Vec2 = require 'modules.brinevector'
local lru = require 'utils.lru'
local memoize = require 'utils.memoize'
local LOS = memoize(require 'modules.line-of-sight')

local targetsHitCache = {
  cache = lru.new(100),
  addTarget = function(self, lightningId, target)
    local targetsById = self.cache:get(lightningId)
    if (not targetsById) then
      targetsById = {}
      self.cache:set(lightningId, targetsById)
    end
    targetsById[target] = true
  end,
  has = function(self, lightningId, target)
    local targetsById = self.cache:get(lightningId)
    return targetsById and targetsById[target]
  end
}

local function findNearestTarget(lightningId, targetX, targetY)
  local mainSceneRef = Component.get('MAIN_SCENE')
  local mapGrid = mainSceneRef.mapGrid
  local gridSize = config.gridSize
  local Map = require 'modules.map-generator.index'
  local losFn = LOS(mapGrid, Map.WALKABLE)
  local getNearestTarget = require 'modules.find-nearest-target'
  return getNearestTarget(collisionWorlds.map, targetX, targetY, 6 * gridSize, losFn, gridSize, function(target)
    return not targetsHitCache:has(lightningId, target)
  end)
end

local ChainLightning = {
  group = groups.all,
  range = 10,
  maxBounces = 2,
  numBounces = 0,
  hitBoxSize = config.gridSize,
}

function ChainLightning.init(self)
  local Position = require 'utils.position'
  local dx, dy = Position.getDirection(self.x, self.y, self.x2, self.y2)
  local trueRange = self.range * config.gridSize
  self.x2 = self.x + dx * trueRange
  self.y2 = self.y + dy * trueRange

  local hbSize = self.hitBoxSize
  self.collision = self:addCollisionObject(
    'projectile',
    self.x, self.y,
    hbSize, hbSize,
    hbSize/2, hbSize/2
  ):addToWorld(collisionWorlds.map)
end

local function createEffect(start, target, hasHit)
  local LightningEffect = require 'components.effects.lightning'
  LightningEffect:add({
    start = start,
    target = target,
    thickness = 1.5,
    duration = 0.4,
    targetPointRadius = hasHit and 12 or 4
  })
end

function ChainLightning.update(self, dt)
  local actualX, actualY, cols, len = self.collision:move(
    self.x2,
    self.y2,
    function(item, other)
      if targetsHitCache:has(self:getId(), other.parent) then
        return false
      end
      if (CollisionGroups.matches(other.group, self.targetGroup)) then
        return 'touch'
      end
      return false
    end
  )
  local hitTriggered = len > 0
  if hitTriggered then
    local alreadyHit = false
    local i=1
    while (i <= len) and (not alreadyHit) do
      local item = cols[i]
      local parent = item.other.parent
      alreadyHit = true
      if parent then
        local targetX, targetY = actualX, actualY
        local start, target = Vec2(self.x, self.y),
          Vec2(targetX, targetY)
        createEffect(start, target, true)

        local isHittable = not CollisionGroups.matches(item.other.group, 'obstacle')
        if isHittable then
          msgBus.send(msgBus.CHARACTER_HIT, {
            parent = parent,
            lightningDamage = math.random(self.lightningDamage.x, self.lightningDamage.y),
            source = self:getId()
          })
          msgBus.send(msgBus.CHARACTER_HIT, {
            parent = parent,
            modifiers = {
              shocked = 1
            },
            duration = 0.2,
            source = 'chain-lightning'
          })
          targetsHitCache:addTarget(self:getId(), parent)

          local canBounce = self.numBounces < self.maxBounces
          local t = canBounce and findNearestTarget(self:getId(), targetX, targetY)
          if t then
            self.initialProps.__index = self.initialProps
            local props = setmetatable({
              id = self:getId(),
              x = targetX,
              y = targetY,
              x2 = t.x,
              y2 = t.y,
              numBounces = self.numBounces + 1
            }, self.initialProps)
            ChainLightning.create(props)
          end
        end
      end
      i = i + 1
    end
  else
    local start, target = Vec2(self.x, self.y),
      Vec2(self.x2, self.y2)
    createEffect(start, target)
  end
  self:delete()
end

return Component.createFactory(ChainLightning)