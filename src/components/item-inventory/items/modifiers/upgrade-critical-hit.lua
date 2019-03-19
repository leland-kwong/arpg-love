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

      if hitMessage.itemSource ~= id or
        props.experienceRequired >= item.experience then
          return
      end

      hitMessage.criticalChance = props.chance
      hitMessage.criticalMultiplier = math.random(
        props.minMultiplier * 100,
        props.maxMultiplier * 100
      ) / 100
      return hitMessage
    end, 1)
  end,
  tooltip = function()
    return {
      type = 'upgrade',
      data = {
        description = {
          template = 'Attacks have a {chance} chance to deal {minMultiplier} - {maxMultiplier} damage',
          data = {
            minMultiplier = 0.2 .. 'x',
            maxMultiplier = 0.4 .. 'x',
            chance = 0.25 .. '%'
          }
        }
      }
    }
  end
})