local itemSystem = require(require('alias').path.itemSystem)
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Enum = require 'utils.enum'
local tween = require 'modules.tween'
local Color = require 'modules.color'

local state = Enum({
  'SHIELD_HIT',
  'SHIELD_UP',
  'SHIELD_DOWN'
})

local ForceField = {
  group = groups.all,
  size = 30,
  shieldHealth = 0,
  maxShieldHealth = 100,
  unhitDuration = 0,
  unhitDurationRequirement = 0,
  rechargeRate = 2,
  baseAbsorption = 0,
  bonusAbsorption = 0,
  maxAbsorption = 50,
  stackIncreaseDelay = 0.5,
  owner = function()
    return Component.get('PLAYER')
  end,
  state = state.SHIELD_DOWN
}

local function hitAnimation()
  local frame = 0
  local animationLength = 3
  while frame < animationLength do
    frame = frame + 1
    coroutine.yield(false)
  end
  coroutine.yield(true)
end

local function nearbyAiFilter(item)
  local collisionGroups = require 'modules.collision-groups'
  return collisionGroups.matches(item.group, 'enemyAi')
end

function ForceField.getAbsorption(self)
  local collisionWorlds = require 'components.collision-worlds'
  local _, len = collisionWorlds.map:queryRect(self.x - self.size, self.y - self.size, self.size * 2, self.size * 2, nearbyAiFilter)
  return math.min(self.maxAbsorption, self.baseAbsorption + (len * self.bonusAbsorption)) / 100
end

function ForceField.init(self)
  self.bonusStacks = 0
  self.clock = 0
  self.totalAbsorption = 0

  self.stackRenderer = function(x, y)
    local AnimationFactory = require 'components.animation-factory'
    local icon = AnimationFactory:newStaticSprite('status-shield')
    local width = icon:getWidth()
    Component.get('hudTextSmallLayer'):add(self.totalAbsorption * 100, Color.WHITE, x + width - 4, y)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(AnimationFactory.atlas, icon.sprite, x, y)
  end

  msgBus.on(msgBus.PLAYER_HIT_RECEIVED, function(msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    self.unhitDuration = 0
    local damageAfterAbsorption = math.max(0, msgValue - (msgValue * self.totalAbsorption))

    if self.shieldHealth > 0 then
      self.hitAnimation = coroutine.wrap(hitAnimation)
    end
    return damageAfterAbsorption
  end, 1)
end

function ForceField.update(self, dt)
  Component.addToGroup(self:getId(), 'hudStatusIcons', self.stackRenderer)
  self.totalAbsorption = self:getAbsorption()

  local nextX, nextY = self.owner():getPosition()
  local hasOwnerMoved = nextX ~= self.previousX or nextY ~= self.previousY
  -- reset clock for bonus stacks
  if hasOwnerMoved then
    self.clock = 0
  end
  self.previousX, self.previousY = nextX, nextY

  local round = require 'utils.math'.round
  self.clock = self.clock + dt
  self.bonusStacks = round(self.clock / self.stackIncreaseDelay)
  self:setDrawDisabled(self.shieldHealth <= 0)

  local hasShield = self.shieldHealth > 0
  local shouldEnableShield = self.unhitDuration >= self.unhitDurationRequirement
  if shouldEnableShield then
    self.shieldHealth = math.min(self.maxShieldHealth, self.shieldHealth + self.rechargeRate)
    self.state = state.SHIELD_UP

    local isNewShield = not hasShield
    if isNewShield then
      love.audio.play(
        love.audio.newSource('built/sounds/force-field.wav', 'static')
      )
      local oSize = self.size
      self.size = 0
      self.tween = tween.new(0.4, self, {size = oSize}, tween.easing.inCubic)
    end
  end

  if self.tween then
    local done = self.tween:update(dt)
    if done then
      self.tween = nil
    end
  end

  if self.hitAnimation then
    local done = self.hitAnimation()
    if done then
      self.hitAnimation = nil
    end
  end
  self.state = self.hitAnimation and state.SHIELD_HIT or state.SHIELD_UP
end

function ForceField.draw(self)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('add')
  local percentHealthLeft = self.shieldHealth / self.maxShieldHealth
  local size = self.size

  local r,g,b = 0.3, 0.5, 1
  if self.state == state.SHIELD_HIT then
    love.graphics.setColor(1,1,1,0.6)
  else
    love.graphics.setColor(r, g, b, 0.2 * percentHealthLeft)
  end
  love.graphics.circle('fill', self.x, self.y, size)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(r, g, b, 0.5)
  love.graphics.circle('line', self.x, self.y, size)

  love.graphics.setBlendMode(oBlendMode)
end

local Factory = Component.createFactory(ForceField)

local forceFieldsByItemId = {}

local function checkExpRequirement(item, props)
  return item.experience >= props.experienceRequired
end

return itemSystem.registerModule({
  name = 'upgrade-force-field',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.UPDATE, function()
      if (not itemState.equipped) then
        local forceFieldRef = forceFieldsByItemId[id]
        if forceFieldRef then
          forceFieldRef:delete(true)
        end
        forceFieldsByItemId[id] = nil
        return msgBus.CLEANUP
      end

      if (not checkExpRequirement(item, props)) then
        return
      end

      if (not forceFieldsByItemId[id]) then
        local playerRef = Component.get('PLAYER')
        local x, y = playerRef:getPosition()
        forceFieldsByItemId[id] = ForceField.create(props)
          :set('x', x)
          :set('y', y)
          :set('drawOrder', function()
            return playerRef:drawOrder() + 3
          end)
          :setParent(playerRef)
      end
    end, 100)
  end,
  tooltip = function(item, props)
    return {
      type = 'upgrade',
      data = {
        title = 'force-field',
        description = {
          template = 'Gain a forcefield that blocks {baseAbsorption}% damage. '

            ..'\n\nFor each nearby enemy gain an extra {bonusAbsorption}% damage reduction.'
            ..'\n\nMaximum absorption is capped to 50%.',
          data = props
        }
      }
    }
  end
})