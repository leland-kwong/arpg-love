local itemSystem =require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local Color = require('modules.color')

return itemSystem.registerModule({
  name = 'heal',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      amount = math.random(props.minHeal, props.maxHeal),
      source = item.__id,
      duration = props.duration,
      property = props.property,
      maxProperty = props.maxProperty,
    })
    love.audio.stop(Sound.drinkPotion)
    love.audio.play(Sound.drinkPotion)
  end,
  tooltip = function(item, props)
    local timeUnit = item.props.duration > 1 and "seconds" or "second"
    local tooltipString = {
      Color.WHITE, 'Restores ',
      Color.LIME, item.props.minHeal .. '-' .. item.props.maxHeal .. ' '..props.property..' ',
      Color.WHITE, 'over ',
      Color.CYAN, item.props.duration .. ' ' .. timeUnit
    }
    return tooltipString
  end
})