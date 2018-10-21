local bump = require 'modules.bump'
local config = require 'config.config'
local Worlds = {}

Worlds.map = bump.newWorld(config.gridSize)
Worlds.gui = bump.newWorld(config.gridSize)

return Worlds