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
    -- automatic draw-ordering based on y position
    drawOrder = function(self)
      --[[
        number of layers between each order. This is to allow multiple different items to be stacked within the same draw order
      ]]
      local layers = 3
      local granularity = self.y / gridSize
      local order = floor(granularity) * layers
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

if config.isDebug then
  Groups.all.drawQueue:onBeforeFlush(function(self)
    local minOrder, maxOrder = self:getStats()
    local maxDivergence = 300
    local divergence = maxOrder - minOrder
    local isDivergingTooMuch = divergence > maxDivergence
    if isDivergingTooMuch then
      local Color = require 'modules.color'
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = 'draw queue divergence',
        description = {
          Color.WHITE, 'draw order gap of ',
          Color.CYAN, divergence,
          Color.WHITE, ' exceeded threshold of ',
          Color.RED, maxDivergence
        }
      })
    end
  end)
end

return Groups