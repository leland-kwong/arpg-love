local Component = require 'modules.component'
local itemSystem =require("components.item-inventory.items.item-system")
local msgBus = require 'components.msg-bus'
local Sound = require 'components.sound'
local Color = require('modules.color')

local speedBoostSoundFilter = {
  type = 'lowpass',
  volume = .5,
}

return itemSystem.registerModule({
  name = 'movespeed-boost',
  type = itemSystem.moduleTypes.EQUIPMENT_ACTIVE,
  active = function(item, props)
    Sound.MOVE_SPEED_BOOST:setFilter(speedBoostSoundFilter)
    love.audio.stop(Sound.MOVE_SPEED_BOOST)
    love.audio.play(Sound.MOVE_SPEED_BOOST)
    local buffDuration = props.speedBoostDuration
    msgBus.send(msgBus.CHARACTER_HIT, {
      parent = Component.get('PLAYER'),
      duration = buffDuration,
      modifiers = {
        moveSpeed = props.speedBoost
      },
      source = 'MOCK_SHOES'
    })
    return {
      cooldown = buffDuration
    }
  end,
  tooltip = function(item, props)
    return {
      Color.YELLOW, '\nactive skill:\n\n',
      Color.WHITE, 'Gain ',
      Color.LIME, props.speedBoost..' extra move speed',
      Color.WHITE, ' for ',
      Color.CYAN, props.speedBoostDuration..' seconds'
    }
  end
})