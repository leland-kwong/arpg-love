local config = require 'config.config'
local noop = require 'utils.noop'
local Map = require 'modules.map-generator.index'
local Camera = require 'modules.camera'
local Component = require 'modules.component'
local Grid = require 'utils.grid'

local floor, max = math.floor, math.max

local function getGridBounds(gridSize, camera)
  local w, e, n, s = camera:getBounds()
  local scale = config.scaleFactor
  return floor(w / gridSize),
    floor(e / gridSize),
    floor(n / gridSize),
    floor(s / gridSize)
end

-- a,b,c are arguments to pass to the callback
local function iterateActiveGrid(self, cb, a, b, c)
  local w,e,n,s = self.bounds.w, self.bounds.e, self.bounds.n, self.bounds.s

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
          cb(self, value, x, y, isInViewport, a, b, c)
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
    local w, e, n, s = getGridBounds(self.gridSize, self.camera)
    self.bounds = {
      w = w,
      e = e,
      n = n,
      s = s
    }

    self.playerVisitedIndices = self.playerVisitedIndices or {}
    local playerRef = Component.get('PLAYER')
    local Position = require 'utils.position'

    local gridX, gridY = Position.pixelsToGridUnits(playerRef.x, playerRef.y, config.gridSize)
    local index = Grid.getIndexByCoordinate(self.grid, gridX, gridY)
    self.isNewGridPosition = (gridX ~= self.lastGridX) or (gridY ~= self.lastGridY)
    self.isVisitedGridPosition = self.playerVisitedIndices[index]
    self.playerVisitedIndices[index] = true
    self.lastGridX, self.lastGridY = gridX, gridY

    self.onUpdateStart(self, dt)
    if self.onUpdate then
      iterateActiveGrid(self, self.onUpdate, dt)
    end
    self.onUpdateEnd(self, dt)
  end,

  setRenderDisabled = function(self, renderDisabled)
    self.renderDisabled = renderDisabled
  end,

  draw = function(self)
    self.renderStart(self)
    if (not self.renderDisabled) and self.render then
      iterateActiveGrid(self, self.render)
    end
    self.renderEnd(self)
  end
}

return mapBlueprint