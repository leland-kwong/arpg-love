local Component = require 'modules.component'
local config = require 'config'

local gridSize = 16 * config.scaleFactor
local floor = math.floor

local Groups = {
  all = Component.newGroup({
    zDepth = function(self)
      local z = floor(self.y / gridSize)
      return z < 1 and 1 or z
    end,
  })
}

return Groups