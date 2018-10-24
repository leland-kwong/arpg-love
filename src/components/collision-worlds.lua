local bump = require 'modules.bump'
local config = require 'config.config'
local Worlds = {}

Worlds.gui = bump.newWorld(config.gridSize)
Worlds.map = bump.newWorld(config.gridSize)
Worlds.zones = bump.newWorld(1) -- we use grid coordinates here

function Worlds.reset(world)
  local items, len = world:getItems()
  for i=1, len do
    world:remove(items[i])
  end
end

return Worlds