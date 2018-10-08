local itemSystem = require(require('alias').path.itemSystem)
local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local Enum = require 'utils.enum'
local tween = require 'modules.tween'

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
  unhitDurationRequirement = 2,
  rechargeRate = 2,
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

function ForceField.init(self)
  msgBus.on(msgBus.PLAYER_HIT_RECEIVED, function(msgValue)
    if self:isDeleted() then
      return msgBus.CLEANUP
    end

    self.unhitDuration = 0
    local damageAfterAbsorption = math.max(0, msgValue - self.shieldHealth)
    -- modify shield health
    self.shieldHealth = math.max(0, self.shieldHealth - msgValue)

    if self.shieldHealth > 0 then
      self.hitAnimation = coroutine.wrap(hitAnimation)
    end
    return damageAfterAbsorption
  end, 1)
end

function ForceField.update(self, dt)
  self.unhitDuration = self.unhitDuration + dt
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
  local size = self.size + (percentHealthLeft * 7)

  local r,g,b = 0.3, 0.5, 1
  if self.state == state.SHIELD_HIT then
    love.graphics.setColor(1,1,1,0.6)
  else
    love.graphics.setColor(r, g, b, 0.5 * percentHealthLeft)
  end
  love.graphics.circle('fill', self.x, self.y, size)

  love.graphics.setLineWidth(1)
  love.graphics.setColor(r, g, b, 0.3)
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
      if (not forceFieldsByItemId[id]) then
        local playerRef = Component.get('PLAYER')
        local x, y = playerRef:getPosition()
        forceFieldsByItemId[id] = ForceField.create({
            x = x,
            y = y,
            size = props.size,
            maxShieldHealth = props.maxShieldHealth,
            unhitDurationRequirement = props.unhitDurationRequirement,
          })
          :set('drawOrder', function()
            return playerRef:drawOrder() + 3
          end)
          :setParent(playerRef)
      end
    end, 100, function()
      return checkExpRequirement(item, props)
    end)
  end,
  tooltip = function(item, props)
    return {
      type = 'upgrade',
      data = {
        description = {
          template = 'Gain a forcefield that blocks {maxShieldHealth} total damage. Recharges when your have not been hit for {unhitDurationRequirement} second(s).',
          data = props
        }
      }
    }
  end
})