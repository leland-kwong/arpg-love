local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'

msgBus.on(msgBus.CHARACTER_HIT, function(msg)
  local uid = require 'utils.uid'
  local hitId = msg.source or uid()
  -- FIXME: sometimes chain lightning triggers a hit for a non-character component
  if msg.parent.isCharacter then
    msg.parent.hitData[hitId] = msg
  end
  return msg
end, 1)

return function(dt)
  for _,component in pairs(groups.character.getAll()) do
    local hitManager = require 'modules.hit-manager'
    local hitCount = hitManager(component, dt, component.onDamageTaken)
  end
end