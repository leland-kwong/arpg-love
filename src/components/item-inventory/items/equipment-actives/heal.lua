local itemDefs = require("components.item-inventory.items.item-definitions")
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local Color = require('modules.color')

return itemDefs.registerModule({
  name = 'heal',
  type = itemDefs.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item)
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      amount = math.random(item.heal[1], item.heal[2]),
      source = item.id,
      duration = item.duration,
      property = 'health',
      maxProperty = 'maxHealth'
    })
    love.audio.stop(Sound.drinkPotion)
    love.audio.play(Sound.drinkPotion)
    return {
      cooldown = item.duration
    }
  end,
  tooltip = function(item)
    local timeUnit = item.duration > 1 and "seconds" or "second"
    local tooltipString = {
      Color.WHITE, 'Restores ',
      Color.LIME, item.minHeal .. '-' .. item.maxHeal .. ' health ',
      Color.WHITE, 'over ',
      Color.CYAN, item.duration .. ' ' .. timeUnit
    }
    return tooltipString
  end
})