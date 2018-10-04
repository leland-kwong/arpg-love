local Component = require 'modules.component'
local gameConfig = require 'config.config'
local itemSystem = require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local memoize = require 'utils.memoize'
local LOS = memoize(require 'modules.line-of-sight')
local extend = require 'utils.object-utils'.extend
local collisionWorlds = require 'components.collision-worlds'

local upgrades = {
  {
    sprite = 'item-upgrade-placeholder-unlocked',
    title = 'Shock',
    description = 'Attacks shock the target, dealing 1-2 lightning damage.',
    experienceRequired = 10,
    props = {
      shockDuration = 0.4,
      minLightningDamage = 1,
      maxLightningDamage = 2
    }
  },
  {
    sprite = 'item-upgrade-placeholder-unlocked',
    title = 'Critical Strikes',
    description = 'Attacks have a 25% chance to deal 1.2 - 1.4x damage',
    experienceRequired = 40,
    props = {
      minCritMultiplier = 0.2,
      maxCritMultiplier = 0.4,
      critChance = 0.25
    }
  },
  {
    sprite = 'item-upgrade-placeholder-unlocked',
    title = 'Ricochet',
    description = 'Attacks bounce to 2 other targets, dealing 50% less damage each bounce.',
    experienceRequired = 120
  }
}

local function triggerUpgrades(item, attack, hitMessage)
  -- shock effect
  local up1 = upgrades[1]
  msgBus.send(msgBus.CHARACTER_HIT, {
    parent = hitMessage.parent,
    duration = up1.props.shockDuration,
    modifiers = {
      shocked = 1
    },
    source = 'INITIATE_SHOCK'
  })
  hitMessage.lightningDamage = math.random(
    up1.props.minLightningDamage,
    up1.props.maxLightningDamage
  )

  -- crit effect
  local up2 = upgrades[2]
  hitMessage.criticalChance = up2.props.critChance
  hitMessage.criticalMultiplier = math.random(
    up2.props.minCritMultiplier * 100,
    up2.props.maxCritMultiplier * 100
  ) / 100

  -- bounce effect
  local up3 = upgrades[3]
  local numBounces, maxBounces = (attack.numBounces or 0), (attack.maxBounces or 1)
  if numBounces >= maxBounces then
    return hitMessage
  end
  local findNearestTarget = require 'modules.find-nearest-target'
  local currentTarget = hitMessage.parent

  local mainSceneRef = Component.get('MAIN_SCENE')
  local mapGrid = mainSceneRef.mapGrid
  local gridSize = gameConfig.gridSize
  local Map = require 'modules.map-generator.index'
  local losFn = LOS(mapGrid, Map.WALKABLE)

  local target = findNearestTarget(
    collisionWorlds.map,
    {currentTarget},
    currentTarget.x,
    currentTarget.y,
    6 * gridSize,
    losFn,
    gridSize
  )

  if target then
    local targetsToIgnore = attack.targetsToIgnore or {}
    targetsToIgnore[currentTarget] = true

    local blueprint = getmetatable(attack)
    blueprint.create({
      x = attack.x,
      y = attack.y,
      x2 = target.x,
      y2 = target.y,
      targetsToIgnore = targetsToIgnore,
      source = attack.source,
      maxBounces = maxBounces,
      numBounces = numBounces + 1,
      color = attack.color,
      targetGroup = attack.targetGroup,
      speed = attack.speed,
      minDamage = attack.minDamage,
      maxDamage = attack.maxDamage
    })
  end

  return hitMessage
end

return itemSystem.registerModule({
  name = 'upgrade-shock',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.CHARACTER_HIT, function(msg)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end
      if props.experienceRequired <= item.experience then
        return triggerUpgrades(
          item,
          msg.collisionItem,
          msg
        )
      end
    end, 1, function(msg)
      return msg.source == id
    end)
  end
})