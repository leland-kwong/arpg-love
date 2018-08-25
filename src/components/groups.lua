--[[
  Component groups for grouping together entities and handling proper draw ordering
]]

local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local config = require 'config.config'

local gridSize = config.gridSize
local floor = math.floor
local max = math.max

local function guiStencil()
  love.graphics.rectangle(
    'fill',
    180,
    30,
    240,
    300
  )
end

local Groups = {
  all = Component.newGroup({
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      --[[
        number of layers between each order. This is to allow multiple different items to be stacked within the same draw order
      ]]
      local layers = 5
      local granularity = self.y / (gridSize / 2)
      local order = floor(granularity) + layers
      return max(1, order)
    end,
  }),

  overlay = Component.newGroup(),
  -- used for in-game debugging, including things like collision object shapes, sprite border-boxes, etc...
  debug = Component.newGroup(),
  gui = Component.newGroup(),
  hud = Component.newGroup(),

  -- used for handling system/os related functionality
  system = Component.newGroup()
}

return Groups