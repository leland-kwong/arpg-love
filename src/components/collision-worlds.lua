local bump = require 'modules.bump'
local config = require 'config.config'
local Worlds = {}

Worlds.map = bump.newWorld(config.gridSize * 4)
Worlds.gui = bump.newWorld(config.gridSize)

return Worlds