local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local config = require 'config'

local gridSize = config.gridSize
local floor = math.floor
local max = math.max
local maxDrawOrder = 100

msgBus.subscribe(function(msgType)
  print(msgType)
  if msgBus.GAME_LOADED ==  msgType then
    maxDrawOrder = floor((love.graphics.getHeight() * config.scaleFactor) / gridSize) + 20
    Component.setMaxOrder(maxDrawOrder)
    print('game loaded', maxDrawOrder)
    return msgBus.CLEANUP
  end
end)


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