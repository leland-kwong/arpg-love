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
    local playerRef = Component.get('PLAYER')
    if playerRef then
      -- Sound.MOVE_SPEED_BOOST:setFilter(speedBoostSoundFilter)
      -- love.audio.stop(Sound.MOVE_SPEED_BOOST)
      -- love.audio.play(Sound.MOVE_SPEED_BOOST)
      local Vec2 = require 'modules.brinevector'
      local magnitude = Vec2(
        playerRef.moveDirectionX * props.distance,
        playerRef.moveDirectionY * props.distance
      )
      Component.addToGroup('dash-force', 'gravForce', {
        magnitude = magnitude,
        actsOn = 'PLAYER',
        duration = props.duration
      })
    end
  end,
  tooltip = function(item, props)
    return {
      template = 'Quickly dashes in the direction that your are moving or facing',
      data = props
    }
  end
})