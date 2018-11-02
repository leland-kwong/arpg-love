local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local AbilityBase = require 'components.abilities.base-class'
local collisionWorlds = require 'components.collision-worlds'
local tween = require 'modules.tween'

local Aoe = AbilityBase({
  opacity = 1,
  area = 1,
  onHit = function(self)
  end,
  drawOrder = function(self)
    return 3
  end
})

local animationEndState = {
  opacity = 0
}

function Aoe.init(self)
  local ox = self.area / 2
  local oy = self.area / 2
  -- adust collision to be centered to target area
  self.collisionX = self.x2 - ox
  self.collisionY = self.y2 - oy

  local items, len = collisionWorlds.map:queryRect(
    self.collisionX,
    self.collisionY,
    self.area,
    self.area,
    function(item)
      return item.group == self.targetGroup
    end
  )
  for i=1, len do
    local it = items[i]
    local msgData = self:onHit()
    msgData.parent = it.parent
    msgData.source = self:getId()
    msgBus.send(msgBus.CHARACTER_HIT, msgData)
  end

  self.animationTween = tween.new(0.3, self, animationEndState)
end

function Aoe.update(self, dt)
  local complete = self.animationTween:update(dt)
  if complete then
    self:delete()
  end
end

function Aoe.draw(self)
  local radius = self.area/2
  love.graphics.setColor(1,0,0,0.2 * self.opacity)
  love.graphics.circle(
    'fill',
    self.x2,
    self.y2,
    radius,
    radius
  )

  love.graphics.setColor(1,0,0,0.8 * self.opacity)
  love.graphics.setLineWidth(2)
  love.graphics.circle(
    'line',
    self.x2,
    self.y2,
    radius,
    radius
  )
end

return Component.createFactory(Aoe)