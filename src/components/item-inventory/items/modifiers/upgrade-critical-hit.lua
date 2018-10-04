local itemSystem = require(require('alias').path.itemSystem)
local msgBus = require 'components.msg-bus'

return itemSystem.registerModule({
  name = 'upgrade-critical-hit',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.CHARACTER_HIT, function(hitMessage)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end
      local isEnoughExperience = props.experienceRequired <= item.experience
      if isEnoughExperience then
        hitMessage.criticalChance = props.chance
        hitMessage.criticalMultiplier = math.random(
          props.minMultiplier * 100,
          props.maxMultiplier * 100
        ) / 100
        return hitMessage
      end
    end, 1, function(msg)
      return msg.source == id and
        props.experienceRequired <= item.experience
    end)
  end,
  tooltip = function()
    return {
      sprite = 'item-upgrade-placeholder-unlocked',
      title = 'Critical Strikes',
      description = 'Attacks have a 25% chance to deal 1.2 - 1.4x damage',
      experienceRequired = 40,
      props = {
        minCritMultiplier = 0.2,
        maxCritMultiplier = 0.4,
        critChance = 0.25
      }
    }
  end
})