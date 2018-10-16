local Component = require 'modules.component'
local gameConfig = require 'config.config'
local itemSystem = require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local extend = require 'utils.object-utils'.extend
local Color = require 'modules.color'

return itemSystem.registerModule({
  name = 'upgrade-shock',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local id = item.__id
    local itemState = itemSystem.getState(item)
    msgBus.on(msgBus.CHARACTER_HIT, function(hitMessage)
      if (not itemState.equipped) then
        return msgBus.CLEANUP
      end
      msgBus.send(msgBus.CHARACTER_HIT, {
        parent = hitMessage.parent,
        duration = props.duration,
        modifiers = {
          shocked = 1
        },
        source = 'INITIATE_SHOCK'
      })
      hitMessage.lightningDamage = math.random(
        props.minDamage,
        props.maxDamage
      )
      return hitMessage
    end, 1, function(msg)
      return msg.source == id and
        props.experienceRequired <= item.experience
    end)
  end,
  tooltip = function(item, props)
    return {
      type = 'upgrade',
      data = {
        experienceRequired = props.experienceRequired,
        description = {
          template = 'Shocks target, dealing {minDamage} - {maxDamage} lightning damage',
          data = props
        }
      }
    }
  end
})