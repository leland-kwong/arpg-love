local bump = require 'modules.bump'
local config = require 'config'
local Worlds = {}

Worlds.map = bump.newWorld(config.gridSize)

return Worlds