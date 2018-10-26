local bump = require 'modules.bump'
local config = require 'config.config'
local Worlds = {}

Worlds.gui = bump.newWorld(config.gridSize)
Worlds.map = bump.newWorld(config.gridSize)

--[[
  Contains only the player's collision. This is useful for querying whether an object would
  collide with the player without having to filter out other collision objects.
]]
Worlds.player = bump.newWorld(config.gridSize)

-- uses grid coordinates
Worlds.zones = bump.newWorld(1)

function Worlds.reset(world)
  local items, len = world:getItems()
  for i=1, len do
    world:remove(items[i])
  end
end

return Worlds