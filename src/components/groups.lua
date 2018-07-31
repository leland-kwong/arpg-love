local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local config = require 'config'

local gridSize = config.gridSize
local floor = math.floor
local max = math.max

local Groups = {
  all = Component.newGroup({
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      local order = floor(self.y / gridSize)
      return max(1, order)
    end,
  }),

  debug = Component.newGroup(),

  gui = Component.newGroup({
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      local order = floor(self.y / gridSize)
      return max(1, order)
    end,
  })
}

return Groups