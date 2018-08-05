local socket = require 'socket'
local pprint = require 'utils.pprint'
local memoize = require 'utils.memoize'
local flowField = require 'scene.sandbox.ai.flow-field'
local groups = require 'components.groups'
local collisionObject = require 'modules.collision'
local bump = require 'modules.bump'

local colWorld = bump.newWorld(50)
local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')

local grid = {
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,1,1,1,0,0,0,1,1,1,0,0,0,0,0},
  {0,0,0,0,1,0,0,0,0,0,1,1,1,0,0,0,0,0},
  {0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0},
  {0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0},
  {0,0,0,0,0,1,1,1,1,1,0,0,0,1,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}

local gridSize = 50
local offX, offY = 300, 75
local WALKABLE = 0

local flowFieldTestBlueprint = {}

local function isOutOfBounds(grid, x, y)
  return y < 1 or x < 1 or y > #grid or x > #grid[1]
end

local function isGridCellVisitable(grid, x, y, dist)
  return not isOutOfBounds(grid, x, y) and
    grid[y][x] == WALKABLE
end

local function pxToGridUnits(screenX, screenY)
  local gridPixelX, gridPixelY = screenX - offX, screenY - offY
  local gridX, gridY =
    math.floor(gridPixelX / gridSize) + 1,
    math.floor(gridPixelY / gridSize) + 1
  return gridX, gridY
end

local function getFlowAtPosition(flowField, x, y)
  if flowField[y] then
    local flowData = flowField[y][x]
    return flowData
  end
  return nil
end

local function createAi(x, y)
  local scale = 1
  local w, h = (gridSize * scale) - 2, (gridSize * scale) - 2
  local colObj = collisionObject
    :new('ai', x, y, w, h)
    :addToWorld(colWorld)
  return {
    x = x,
    y = y,
    w = w,
    h = h,
    speed = 300,
    collision = colObj,
    move = function(self, flowField, dt)
      local actualX, actualY = self.x + offX, self.y + offY
      local slop = 5 * scale
      local gridX, gridY = pxToGridUnits(self.x, self.y)
      local ffv = flowField[gridY][gridX] -- flow field value
      local isNewTile = ((actualX % gridSize) <= slop and (actualY % gridSize) <= slop)
      -- if its a new tile lets use its vector info
      if isNewTile then
        local normalize = require'utils.position'.normalizeVector
        local dirX, dirY = normalize(ffv[1], ffv[2])
        self.dx = self.speed * dirX * dt
        self.dy = self.speed * dirY * dt
      end

      local nextX, nextY = self.x + self.dx, self.y + self.dy
      local adjustedX, adjustedY, cols = self.collision:move(nextX, nextY)

      if #cols > 0 then
        local c = cols[1]
        if c.other.group == 'wall' then
          local n = c.normal
          -- When ai is moving opposite the normal we'll adjust the positioning so its at least
          -- moving somewhat diagonally to wall. This prevents it from being stuck trying to go around the wall.
          if n.x ~= 0 and n.y == 0 then
            local yAxisBias = (adjustedY - offY) % gridSize
            if yAxisBias < (gridSize / 2) then
              adjustedY = adjustedY - 1
            else
              adjustedY = adjustedY + 1
            end
          end

          if n.x == 0 and n.y ~= 0 then
            local xAxisBias = (adjustedX - offX) % gridSize
            if xAxisBias < (gridSize / 2) then
              adjustedX = adjustedX - 1
            else
              adjustedX = adjustedX + 1
            end
          end
        end
      end

      self.x = adjustedX
      self.y = adjustedY
    end,
    draw = function(self)
      love.graphics.setColor(1,0.2,0, 0.8)
      local padding = 0
      love.graphics.rectangle(
        'fill',
        self.x + padding,
        self.y + padding,
        self.w - padding * 2,
        self.h - padding * 2
      )
    end
  }
end

function flowFieldTestBlueprint.init(self)
  local iterateGrid = require 'utils.iterate-grid'
  self.wallCollisions = {}
  iterateGrid(grid, function(v, x, y)
    if v ~= WALKABLE then
      self.wallCollisions[y] = self.wallCollisions[y] or {}
      self.wallCollisions[y][x] = collisionObject:new(
        'wall',
        ((x - 1) * gridSize) + offX,
        ((y - 1) * gridSize) + offY,
        gridSize, gridSize
      ):addToWorld(colWorld)
    end
  end)

  self.flowField = flowField(grid, 5, 2, isGridCellVisitable)
  self.ai = createAi(offX, offY)
end

function flowFieldTestBlueprint.update(self, dt)
  if love.mouse.isDown(1) then
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local gridX, gridY = pxToGridUnits(mx, my)

    if isOutOfBounds(grid, gridX, gridY) then
      return
    end

    local gridValue = grid[gridY][gridX]
    if gridValue ~= WALKABLE then
      return
    end

    local ts = socket.gettime()
    self.flowField = flowField(grid, gridX, gridY, isGridCellVisitable)
    self.executionTimeMs = (socket.gettime() - ts) * 1000
  end

  self.ai:move(self.flowField, dt)
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
local COLOR_WALKABLE = {0.2,0.35,0.55,1}
local COLOR_START_POINT = {0,1,1}

function flowFieldTestBlueprint.draw(self)
  love.graphics.clear(0.1,0.1,0.1,1)

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
        gridSize - 2,
        gridSize - 2
      )

      -- wall collision rectangle
      if self.wallCollisions[y] and self.wallCollisions[y][x] then
        love.graphics.setColor(0,0.6,1,0.4)
        local margin = 2
        love.graphics.rectangle(
          'line',
          drawX + margin,
          drawY + margin,
          gridSize - margin * 2,
          gridSize - margin * 2
        )
      end

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

  self.ai:draw()

  for i=1, #arrowDrawQueue do
    arrowDrawQueue[i]()
  end

  for i=1, #textDrawQueue do
    textDrawQueue[i]()
  end
end

return groups.gui.createFactory(flowFieldTestBlueprint)