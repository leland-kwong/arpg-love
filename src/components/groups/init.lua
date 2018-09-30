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
  --[[
    This is for change that seldom change their draw order. This way we can prevent the min/max order queue from
    spreading out too much. For example, if the main scene's draw order is 1, and the player's draw order is 10000, then
    the draw queue will have to skip 99999 iterations just to go from 1-10000.
  ]]
  firstLayer = Component.newGroup(),
  all = Component.newGroup({
    drawLayersPerGridCell = 10,
    -- automatic draw-ordering based on y position
    drawOrder = function(self, component)
      --[[
        number of layers between each order. This is to allow multiple different items to be stacked within the same draw order
      ]]
      local orderByTilePosition = floor(component.y / gridSize)
      local order = orderByTilePosition * self.drawLayersPerGridCell - 2
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