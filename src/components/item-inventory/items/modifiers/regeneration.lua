local itemSystem = require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Color = require('modules.color')
local Sound = require 'components.sound'

return itemSystem.registerModule({
  name = 'modifier-regeneration',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(item, props)
    local duration = math.pow(10, 100)
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      amount = duration * props.rate,
      source = item.__id,
      duration = duration,
      property = props.property,
      maxProperty = props.maxProperty,
    })
  end,
  tooltip = function(item, props)
    return {
      type = 'upgrade',
      data = {
        description = {
          template = '+{rate} health regeneration',
          data = props
        }
      }
    }
  end
})