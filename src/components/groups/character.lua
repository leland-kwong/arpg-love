local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local lootSystem = require'components.groups.loot'.system
local tween = require 'modules.tween'

local characterHitMessagePropTypes = {
  source = {
    string = true,
    number = true
  }
}

local hitMessageMt = {
  damage = 0,
  lightningDamage = 0,
  coldDamage = 0
}
hitMessageMt.__index = hitMessageMt
msgBus.on(msgBus.CHARACTER_HIT, function(msg)
  local sourceValueType = type(msg.source)
  if (not characterHitMessagePropTypes.source[sourceValueType]) then
    print('[WARNING]: invalid source value type'..sourceValueType)
  end

  -- FIXME: sometimes chain lightning triggers a hit for a non-character component
  if msg.parent.isCharacter then
    if msg.parent.invulnerable then
      return nil
    end
    local uid = require 'utils.uid'
    local hitId = msg.source or uid()
    msg.parent.hitData[hitId] = msg
  end

  -- add item source if applicable
  local entity = Component.get(msg.source)
  local itemSource = entity and entity.source
  msg.itemSource = itemSource

  setmetatable(msg, hitMessageMt)
  return msg
end, 1)


local function showHealing(c, prop, previousProp, accumulatedProp, color, isShowFrame)
  local Math = require 'utils.math'
  local propertyChange = Math.round(c[prop] - (c[previousProp] or 0))
  c[previousProp] = c[prop]
  local isHealChange = propertyChange > 0
  if (isHealChange) then
    c[accumulatedProp] = (c[accumulatedProp] or 0) + propertyChange
  end

  local roundedTotal = Math.round(c[accumulatedProp])
  if isShowFrame and (roundedTotal > 0) then
    local popupText = Component.get('popupText')
    popupText:new(roundedTotal, c.x, c.y - c.h, nil, color)
    c[accumulatedProp] = 0
  end
end

local frameCount = 0
return function(dt)
  frameCount = frameCount + 1
  local healingNumberFrequency = 30
  local isShowHealingNumberFrame = (frameCount % healingNumberFrequency == 0)

  for componentId,c in pairs(groups.character.getAll()) do
    if c.isDestroyed then
      local destroyCompleted = false
      if c.frozen then
        local Effects = require 'components.effects'
        local sizeMin = c.h/6
        Effects('freeze')(c.x, c.y, c.w/2, 150, 10, 14, sizeMin, sizeMin + 1, 0.5)
        destroyCompleted = true
      else
        c.destroyedAnimation = c.destroyedAnimation
          or tween.new(0.5, c, {opacity = 0}, tween.easing.outCubic)
        destroyCompleted = c.destroyedAnimation:update(dt)
      end

      if (not c._destroyTriggered) then
        c._destroyTriggered = true
        c:onDestroyStart()
        Component.addToGroup(c, lootSystem, c.itemLevel)
        c.collision:delete()
        msgBus.send(msgBus.ENEMY_DESTROYED, {
          parent = c,
          x = c.x,
          y = c.y,
          experience = c.experience
        })
      end

      if destroyCompleted then
        c:delete(true)
        if c.onFinal then
          c:onFinal()
        end
      end
    else
      local Stats = require 'modules.stats'
      c.stats = c.stats.hasChanges and Stats:new(c.baseStats and c:baseStats()) or c.stats

      local hitManager = require 'modules.hit-manager'
      hitManager(c, dt, c.onDamageTaken)
      c.frozen = c.stats:get('freeze') > 0
      local newlyFrozen = c.frozen and (not c.wasFrozen)
      if newlyFrozen then
        local Sound = require 'components.sound'
        Sound.playEffect('freeze_object.wav')
      end
      c.wasFrozen = c.frozen

      if c.showHealing then
        local Color = require 'modules.color'
        showHealing(c, 'health', 'previousHealth', 'accumulatedHealthHeal', Color.LIME, isShowHealingNumberFrame)
        showHealing(c, 'energy', 'previousEnergy', 'accumulatedEnergyHeal', Color.DEEP_BLUE, isShowHealingNumberFrame)
      end
    end
  end
end