local config = require 'config.config'
local noop = require 'utils.noop'
local Map = require 'modules.map-generator.index'
local Camera = require 'modules.camera'

local floor, max = math.floor, math.max

local function getGridBounds(gridSize, camera)
  local w, e, n, s = camera:getBounds()
  local scale = config.scaleFactor
  return w / gridSize,
    e / gridSize,
    n / gridSize,
    s / gridSize
end

-- a,b,c are arguments to pass to the callback
local function iterateActiveGrid(self, cb, a, b, c)
  local w,e,n,s = getGridBounds(self.gridSize, self.camera)
  w = floor(w)
  e = floor(e)
  n = floor(n)
  s = floor(s)

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
  local startX = w - self.offset - thresholdWest
  local endX = e + self.offset + thresholdEast
  local startY = n - self.offset
  local endY = (s + self.offset + thresholdSouth)
  local y = startY
  while y < endY do
    local isInRowViewport = y >= n and y <= s
    local row = self.grid[y]
    if row then
      for x=startX, endX do
        -- adjust coordinates to be integer values since grid coordinates are integers
        local value = row[x]
        local isInColViewport = x >= w and x <= e
        local isInViewport = isInRowViewport and isInColViewport
        local tileExists = value ~= nil
        if tileExists then
          cb(self, value, x, y, originX, originY, isInViewport, a, b, c)
        end
      end
    end
    y = y + 1
  end
end

local mapBlueprint = {
  offset = 0,
  gridSize = 16,
  walkable = 1,
  camera = Camera,
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
    self.onUpdateStart(self, dt)
    if self.onUpdate then
      iterateActiveGrid(self, self.onUpdate, dt)
    end
    self.onUpdateEnd(self, dt)
  end
}

return mapBlueprint