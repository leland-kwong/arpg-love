local Component = require 'modules.component'
local config = require 'config'

local gridSize = 16 * config.scaleFactor
local floor = math.floor
local max = math.max

local maxDrawOrder = floor(love.graphics.getHeight() / gridSize) + 20
Component.setMaxOrder(maxDrawOrder)

local Groups = {
  all = Component.newGroup({
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      local order = floor(self.y / gridSize)
      return max(1, order)
    end,
  }),

  gui = Component.newGroup({
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      local order = floor(self.y / gridSize)
      return max(1, order)
    end,
  }),

  DRAW_ORDER_CONSOLE = function() return maxDrawOrder end,
  DRAW_ORDER_COLLISION_DEBUG = function() return maxDrawOrder - 1 end,
}

return Groups