local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'

Component.newGroup({
  name = 'gameWorld'
})

msgBus.on(msgBus.NEW_GAME, function()
  for _,component in pairs(Component.groups.gameWorld.getAll()) do
    component:delete(true)
  end
end)