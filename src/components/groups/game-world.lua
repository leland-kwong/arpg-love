local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local collisionWorlds = require 'components.collision-worlds'

Component.newGroup({
  name = 'gameWorld'
})

local function resetGameWorld()
  for _,component in pairs(Component.groups.gameWorld.getAll()) do
    component:delete(true)
  end
end

msgBus.on(msgBus.MAP_UNLOADED, resetGameWorld)
msgBus.on(msgBus.GAME_UNLOADED, resetGameWorld)