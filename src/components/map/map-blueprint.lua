local config = require 'config'
local iterateGrid = require 'utils.iterate-grid'
local bump = require 'modules.bump'
local pprint = require 'utils.pprint'
local noop = require 'utils.noop'
local Map = require 'modules.map-generator.index'
local Camera = require 'modules.camera'

local floor, max = math.floor, math.max

local function getGridBounds(gridSize, camera)
  local w, e, n, s = camera:getBounds(false)
  local scale = config.scaleFactor
  return w / scale / gridSize,
    e / scale / gridSize,
    n / scale / gridSize,
    s / scale / gridSize
end

-- a,b,c are arguments to pass to the callback
local function iterateActiveGrid(self, cb, a, b, c)
  local w,e,n,s = getGridBounds(self.gridSize, self.camera)

  -- viewport origin
  local originX = max(1, w)
  local originY = max(1, s)

  --[[
    FIXME: thresholds are here as a way to make sure rendering reaches the edge of the screen.
    The "correct" way to do it would be to figure out exactly what the edges are instead of just adding to the edges to fill.
  ]]
  local thresholdSouth = 3
  local thresholdWest = 0
  local thresholdEast = 1

  local y = n - self.offset
  while y < (s + self.offset + thresholdSouth) do
    local isInRowViewport = y >= n and y <= s
    local startX = w - self.offset - thresholdWest
    local endX = e + self.offset + thresholdEast
    local _y = floor(y)
    local row = self.grid[_y]
    for x=startX, endX do
      -- adjust coordinates to be integer values since grid coordinates are integers
      local _x = floor(x)
      local value = row and row[_x]
      local isInColViewport = x >= w and x <= e
      local isInViewport = isInRowViewport and isInColViewport
      local tileExists = value ~= nil
      if tileExists then
        cb(self, value, _x, _y, originX, originY, isInViewport, a, b, c)
      end
    end
    y = y + 1
  end
end

local mapBlueprint = {
  offset = 0,
  gridSize = 16,
  walkable = 1,
  camera = Camera(),
  grid = {
    {}
  },
  onUpdateStart = noop,
  onUpdate = nil,
  onUpdateEnd = noop,
  renderStart = noop,
  render = nil,
  renderEnd = noop,

  getGridBounds = getGridBounds,

  update = function(self, dt)
    self.onUpdateStart(self)
    if self.onUpdate then
      iterateActiveGrid(self, self.onUpdate, dt)
    end
    self.onUpdateEnd(self)
  end,

  draw = function(self)
    self.renderStart(self)
    if self.render then
      iterateActiveGrid(self, self.render)
    end
    self.renderEnd(self)
  end
}

return mapBlueprint