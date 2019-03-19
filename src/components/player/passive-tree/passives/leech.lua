return function(data, prop, maxProp, msg, msgBus)
  local collisionGroups = require 'modules.collision-groups'
  local Component = require 'modules.component'
  local c = Component.get(msg.receiverId)
  if collisionGroups.matches(c.class, 'enemyAi') then
    local uid = require 'utils.uid'
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      amount = data.value.value * msg.totalDamage,
      source = uid(),
      duration = data.value.duration,
      property = prop,
      maxProperty = maxProp
    })
  end
end