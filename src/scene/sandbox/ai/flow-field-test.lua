local socket = require 'socket'
local pprint = require 'utils.pprint'
local memoize = require 'utils.memoize'
local flowField = memoize(require 'scene.sandbox.ai.flow-field')
local groups = require 'components.groups'

local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')

local grid = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,0,1},
  {1,0,0,0,1,0,0,0,0,0,1,1,1,0,0,0,0,1},
  {1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,0,1},
  {1,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1},
  {1,0,0,0,0,1,1,1,1,1,0,0,1,0,0,0,0,1},
  {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

-- pprint(
--   flowField(grid, 2, 1)
-- )

local gridSize = 50
local offX, offY = 300, 75
local WALKABLE = 0

local flowFieldTestBlueprint = {}

local function isGridCellVisitable(grid, x, y, dist)
  return grid[y][x] == WALKABLE
end

function flowFieldTestBlueprint.init(self)
  self.flowField = flowField(grid, 2, 2, isGridCellVisitable)
end

function flowFieldTestBlueprint.update(self)
  if love.mouse.isDown(1) then
    local ts = socket.gettime()

    local mx, my = love.mouse.getX(), love.mouse.getY()
    local gridPixelX, gridPixelY = mx - offX, my - offY
    local gridX, gridY =
      math.floor(gridPixelX / gridSize) + 1,
      math.floor(gridPixelY / gridSize) + 1
    local gridValue = grid[gridY][gridX]

    if gridValue ~= WALKABLE then
      return
    end
    self.flowField = flowField(grid, gridX, gridY, isGridCellVisitable)
    self.executionTimeMs = (socket.gettime() - ts) * 1000
  end
end

local function arrowRotationFromDirection(dx, dy)
  if dx < 0 then
    if dy < 0 then
      return math.rad(-45)
    end
    if dy > 0 then
      return math.rad(225)
    end
    return math.rad(-90)
  end
  if dx > 0 then
    if dy < 0 then
      return math.rad(-315)
    end
    if dy > 0 then
      return math.rad(135)
    end
    return math.rad(90)
  end
  if dy < 0 then
    return math.rad(0)
  end
  return math.rad(180)
end

local COLOR_UNWALKABLE = {0.2,0.2,0.2,1}
local COLOR_WALKABLE = {0.2,0.3,0.5,1}
local COLOR_START_POINT = {0,1,1}

function flowFieldTestBlueprint.draw(self)
  love.graphics.clear(0,0,0,1)

  love.graphics.setColor(1,1,1,1)
  love.graphics.print('CLICK GRID TO SET CONVERGENCE POINT', offX + 20, 20)

  love.graphics.setColor(0.5,0.5,0.5)
  if self.executionTimeMs ~= nil then
    love.graphics.print(
      string.format('execution time: %.4f(ms)', self.executionTimeMs),
      offX + 20,
      50
    )
  end

  local textDrawQueue = {}
  local arrowDrawQueue = {}

  for y=1, #grid do
    local row = self.flowField[y] or {}
    for x=1, #grid[1] do
      local cell = row[x]
      local drawX, drawY =
        ((x-1) * gridSize) + offX,
        ((y-1) * gridSize) + offY

      local oData = grid[y][x]
      local ffd = row[x] -- flow field cell data
      local isStartPoint = ffd and (ffd[1] == 0 and ffd[2] == 0)
      if isStartPoint then
        love.graphics.setColor(COLOR_START_POINT)
      else
        love.graphics.setColor(
          oData == WALKABLE and
            COLOR_WALKABLE or
            COLOR_UNWALKABLE
        )
      end
      love.graphics.rectangle(
        'fill',
        drawX + 1,
        drawY + 1,
        gridSize - 1,
        gridSize - 1
      )
      if cell then
        arrowDrawQueue[#arrowDrawQueue + 1] = function()
          -- arrow
          love.graphics.setColor(1,1,0.2)
          if not isStartPoint then
            local rot = arrowRotationFromDirection(ffd[1], ffd[2])
            local offsetCenter = 8
            love.graphics.draw(
              arrow,
              drawX + 25,
              drawY + 26,
              rot,
              1,
              1,
              8,
              8
            )
          end
        end

        textDrawQueue[#textDrawQueue + 1] = function()
          -- text
          love.graphics.scale(0.5)
          love.graphics.setColor(0.6,0.6,0.6,1)
          -- direction vectors
          love.graphics.print(
            row[x][1]..' '..row[x][2],
            (drawX + 5) * 2,
            (drawY + 5) * 2
          )
          -- distance
          love.graphics.print(
            row[x][3],
            (drawX + 25) * 2,
            (drawY + 38) * 2
          )
          love.graphics.scale(2)
        end
      end
    end
  end

  for i=1, #arrowDrawQueue do
    arrowDrawQueue[i]()
  end

  for i=1, #textDrawQueue do
    textDrawQueue[i]()
  end
end

return groups.gui.createFactory(flowFieldTestBlueprint)