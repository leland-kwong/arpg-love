local Component = require 'modules.component'
local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local mapBlueprint = require 'components.map.map-blueprint'
local config = require 'config.config'
local memoize = require 'utils.memoize'
local Grid = require 'utils.grid'

local COLOR_TILE_OUT_OF_VIEW = {1,1,1,0.3}
local COLOR_TILE_IN_VIEW = {1,1,1,1}
local COLOR_WALL = {1,1,1,0.7}
local COLOR_GROUND = {0,0,0,0.2}
local floor = math.floor
local minimapTileRenderers = {
  -- obstacle
  [0] = function(self, x, y)
    love.graphics.setColor(COLOR_WALL)
    local rectSize = 1
    local x = (self.x * rectSize) + x
    local y = (self.y * rectSize) + y
    love.graphics.rectangle(
      'fill',
      x, y, rectSize, rectSize
    )
  end,
  -- walkable
  [1] = function(self, x, y)
    love.graphics.setColor(COLOR_GROUND)
    local rectSize = 1
    local x = (self.x * rectSize) + x
    local y = (self.y * rectSize) + y
    love.graphics.rectangle(
      'fill',
      x, y, rectSize, rectSize
    )
  end,
}

local function drawPlayerPosition(self, centerX, centerY)
  local playerDrawX, playerDrawY = self.x + centerX, self.y + centerY
  -- translucent background around player for better visibility
  love.graphics.setColor(1,1,1,0.3)
  local bgRadius = 5
  love.graphics.circle('fill', playerDrawX, playerDrawY, bgRadius)

  -- granular player position indicator
  love.graphics.setColor(1,1,0)
  love.graphics.circle('fill', playerDrawX, playerDrawY, 1)
end

local function drawDynamicBlocks(self)
  for coordIndex, renderFn in pairs(self.blocks) do
    local x, y = Grid.getCoordinateByIndex(self.grid, coordIndex)
    love.graphics.push()
    love.graphics.translate(self.x + x, self.y + y)
    renderFn()
    love.graphics.pop()
  end
  self.blocks = {}
end

-- minimap
local MiniMap = objectUtils.assign({}, mapBlueprint, {
  id = 'miniMap',
  class = 'miniMap',
  group = groups.hud,
  x = 50,
  y = 50,
  w = 100,
  h = 100,

  getRectangle = function(self)
    return self.x, self.y, self.w, self.h
  end,

  init = function(self)
    Component.addToGroup(self, 'mapStateSerializers')

    -- 1-d array of visited indices
    self.visitedIndices = self.visitedIndices or {}
    self.playerVisitedIndices = {}

    self.canvas = love.graphics.newCanvas()

    local x,y,w,h = self:getRectangle()
    self.stencil = function()
      love.graphics.rectangle(
        'fill', x, y, w, h
      )
    end
    self.blocks = {}

    -- pre-draw indices that have already been visited
    self:renderStart()
    for index in pairs(self.visitedIndices) do
      local x, y = Grid.getCoordinateByIndex(self.grid, index)
      local value = Grid.get(self.grid, x, y)
      local tileRenderer = minimapTileRenderers[value]
      if tileRenderer then
        tileRenderer(self, x, y)
      end
    end
    self:renderEnd()
  end,

  renderStart = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self.canvas)
    self:setRenderDisabled(self.isVisitedGridPosition)
  end,

  render = function(self, value, gridX, gridY)
    local tileRenderer = minimapTileRenderers[value]
    if tileRenderer then
      local index = Grid.getIndexByCoordinate(self.grid, gridX, gridY)
      if self.visitedIndices[index] then
        return
      end
      tileRenderer(self, gridX, gridY)
      self.visitedIndices[index] = true
    end
  end,

  renderEnd = function(self)
    local centerX, centerY = self.w/2, self.h/2

    love.graphics.setCanvas()
    love.graphics.scale(self.scale)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    -- translate the minimap so its centered around the player
    local cameraX, cameraY  = self.camera:getPosition()
    local Position = require 'utils.position'
    local tx, ty = centerX - cameraX/self.gridSize, centerY - cameraY/self.gridSize
    love.graphics.translate(tx, ty)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode('alpha')
    love.graphics.draw(self.canvas)
    drawDynamicBlocks(self, centerX, centerY)
    love.graphics.setStencilTest()
    love.graphics.pop()

    -- border
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.setLineWidth(0.5)
    local x,y,w,h = self:getRectangle()
    love.graphics.rectangle('line', x, y, w, h)
    drawPlayerPosition(self, centerX, centerY)
  end
})

-- adds a block for the next draw frame, and gets removed automatically each frame
function MiniMap.renderBlock(self, gridX, gridY, renderFn)
  local bounds = self.bounds
  if bounds then
    local thresholdX, thresholdY = 20, 40
    local isOutOfBounds = gridX < bounds.w - thresholdX or
      gridX > bounds.e + thresholdX or
      gridY < bounds.n - thresholdY or
      gridY > bounds.s + thresholdY
    if isOutOfBounds then
      return
    end
  end
  local Grid = require 'utils.grid'
  local index = Grid.getIndexByCoordinate(self.grid, gridX, gridY)
  self.blocks[index] = renderFn
end

function MiniMap.serialize(self)
  return objectUtils.immutableApply(self.initialProps, {
    visitedIndices = self.visitedIndices
  })
end

return Component.createFactory(MiniMap)