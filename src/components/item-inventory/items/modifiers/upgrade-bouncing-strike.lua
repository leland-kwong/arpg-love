local Component = require 'modules.component'
local memoize = require 'utils.memoize'
local LOS = memoize(require 'modules.line-of-sight')
local itemSystem = require(require('alias').path.itemSystem)
local msgBus = require 'components.msg-bus'
local gameConfig = require 'config.config'
local collisionWorlds = require 'components.collision-worlds'

return itemSystem.registerModule({
  name = 'upgrade-bounce',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.CHARACTER_HIT, function(hitMessage)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end

      local attack = hitMessage.collisionItem
      local numBounces, maxBounces = (attack.numBounces or 0), props.maxBounces
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

        local blueprint = Component.getBlueprint(attack)
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
    end, nil, function(msg)
      return msg.source == id and
        props.experienceRequired <= item.experience
    end)
  end,
  tooltip = function()
    return {
      type = 'upgrade',
      data = {
        description = {
          template = 'Attacks bounce to {maxBounces} additional target(s)',
          data = {
            maxBounces = 1
          }
        },
      }
    }
  end
})