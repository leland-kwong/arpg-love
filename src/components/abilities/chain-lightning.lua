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

local ChainLightning = {
  group = groups.all,
}

function ChainLightning.init(self)
  local hitBoxSize = config.gridSize
  self.collision = self:addCollisionObject(
    'projectile',
    self.x, self.y,
    hitBoxSize, hitBoxSize,
    hitBoxSize/2, hitBoxSize/2
  ):addToWorld(collisionWorlds.map)
end

function ChainLightning.update(self, dt)
  local actualX, actualY, cols, len = self.collision:move(
    self.x2,
    self.y2,
    function(item, other)
      if (CollisionGroups.matches(other.group, self.targetGroup)) then
        return 'touch'
      end
      return false
    end
  )
  local hitTriggered = len > 0
  local LightningEffect = require 'components.effects.lightning'
  if hitTriggered then
    local alreadyHit = false
    local i=1
    while (i <= len) and (not alreadyHit) do
      local item = cols[i]
      local parent = item.other.parent
      if parent then
        alreadyHit = true

        local start, target = Vec2(self.x, self.y),
          Vec2(actualX, actualY)
        local source = {
          start = start,
          target = target,
          duration = 0.4
        }
        LightningEffect:add(source)

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
      end
      i = i + 1
    end
  else
    local start, target = Vec2(self.x, self.y),
      Vec2(self.x2, self.y2)
    local source = {
      start = start,
      target = target,
      duration = 0.4
    }
    LightningEffect:add(source)
  end
  self:delete()
end

return Component.createFactory(ChainLightning)