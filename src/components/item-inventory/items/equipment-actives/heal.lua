local itemSystem =require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local Color = require('modules.color')

return itemSystem.registerModule({
  name = 'heal',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item)
    local props = item.props
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      amount = math.random(props.heal[1], props.heal[2]),
      source = item.__id,
      duration = item.props.duration,
      property = 'health',
      maxProperty = 'maxHealth'
    })
    love.audio.stop(Sound.drinkPotion)
    love.audio.play(Sound.drinkPotion)
    return {
      cooldown = props.duration
    }
  end,
  tooltip = function(item)
    local timeUnit = item.props.duration > 1 and "seconds" or "second"
    local tooltipString = {
      Color.WHITE, 'Restores ',
      Color.LIME, item.props.heal[1] .. '-' .. item.props.heal[2] .. ' health ',
      Color.WHITE, 'over ',
      Color.CYAN, item.props.duration .. ' ' .. timeUnit
    }
    return tooltipString
  end
})