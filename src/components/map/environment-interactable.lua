local Component = require 'modules.component'
local collisionGroups = require 'modules.collision-groups'
local collisionWorlds = require 'components.collision-worlds'
local groups = require 'components.groups'
local AnimationFactory = require 'components.animation-factory'
local msgBus = require 'components.msg-bus'
local f = require 'utils.functional'
local setupChanceFunction = require 'utils.chance'
local onDamageTaken = require 'modules.handle-damage-taken'
local Enum = require 'utils.enum'

local states = Enum({
  'HIT',
  'IDLE',
  'DESTROYING',
  'DESTROYED'
})

local generateTreasureCacheStyle = setupChanceFunction(f.reduce({
  'environment-breakable-1',
  'environment-breakable-2',
  'environment-breakable-3'
}, function(list, v)
  table.insert(list, {
    chance = 1,
    __call = function()
      return v
    end
  })
  return list
end, {}))

local BaseStatModifiers = require'components.state.base-stat-modifiers'
local extend = require 'utils.object-utils'.extend
local EnvironmentInteractable = extend(BaseStatModifiers(), {
  -- debug = true,
  group = groups.all,
  itemLevel = 0,
  maxHealth = 1,
  experience = 0,
  opacity = 1,
  state = states.IDLE
})

local function hitAnimation()
  local frame = 0
  local animationLength = 4
  while frame < animationLength do
    frame = frame + 1
    coroutine.yield(false)
  end
  coroutine.yield(true)
end

msgBus.on(msgBus.CHARACTER_HIT, function(msgValue)
  local component = msgValue.parent
  if Component.getBlueprint(msgValue.parent) == EnvironmentInteractable then
    component.hitAnimation = coroutine.wrap(hitAnimation)
  end
end)

function EnvironmentInteractable.init(self)
  Component.addToGroup(self, groups.character)
  Component.addToGroup(self, 'autoVisibility')
  self.onDamageTaken = onDamageTaken
  self.health = self.maxHealth

  self.animation = AnimationFactory:newStaticSprite(
    generateTreasureCacheStyle()
  )
  local offsetY = 5
  local w, h = self.animation:getWidth(), self.animation:getHeight()
  self.w, self.h = w, h
  self.ox, self.oy = self.animation:getOffset()
  self.x, self.y = self.x + self.ox, self.y + self.oy
  local cGroup = collisionGroups.create(
    collisionGroups.environment
  )
  self.collision = self:addCollisionObject(
    cGroup,
    self.x,
    self.y,
    w + 1,
    h,
    self.ox,
    self.oy
  ):addToWorld(collisionWorlds.map)
end

function EnvironmentInteractable.update(self, dt)
  if self.destroyedAnimation then
    return
  end

  self:setDrawDisabled(not self.isInViewOfPlayer)

  self.state = self.hitAnimation and states.HIT or states.IDLE
  if self.hitAnimation then
    local done = self.hitAnimation(dt)
    if done then
      self.hitAnimation = nil
    end
  end
end

local function draw(self, x, y, scaleX, scaleY)
  love.graphics.draw(
    AnimationFactory.atlas,
    self.animation.sprite,
    x,
    y,
    0,
    scaleX or 1,
    scaleY or 1,
    self.ox,
    self.oy
  )
end

function EnvironmentInteractable.draw(self)
  local w, h = self.animation:getWidth(), self.animation:getHeight()
  -- shadow
  love.graphics.setColor(0,0,0,0.25 * self.opacity)
  local shadowScale = 0.5
  draw(self, self.x, self.y + (self.h * shadowScale), 1, -0.5)

  local oBlendMode
  if self.state == states.HIT then
    oBlendMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode('add')
    love.graphics.setColor(3,3,3)
  end

  love.graphics.setColor(1,1, 1, 1 * self.opacity)
  draw(self, self.x, self.y)

  if self.state == states.HIT then
    love.graphics.setBlendMode(oBlendMode)
  end
end

return Component.createFactory(EnvironmentInteractable)