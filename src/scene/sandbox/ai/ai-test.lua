local Component = require 'modules.component'
local socket = require 'socket'
local pprint = require 'utils.pprint'
local memoize = require 'utils.memoize'
local flowField = require 'modules.flow-field.flow-field'
local grid = require 'scene.sandbox.ai.grid'
local groups = require 'components.groups'
local collisionObject = require 'modules.collision'
local bump = require 'modules.bump'
local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')
local f = require'utils.functional'
local Ai = require'components.ai.ai'
local Math = require'utils.math'

local gridSize = 32
local offX, offY = 100, 0
local WALKABLE = 0

local flowFieldTestBlueprint = {
  group = groups.hud,
  showFlowFieldText = false,
  showGridCoordinates = true,
  showAiPath = false,
  showAi = true
}

local colWorld = bump.newWorld(gridSize)

local function isOutOfBounds(grid, x, y)
  return y < 1 or x < 1 or y > #grid or x > #grid[1]
end

local function isGridCellVisitable(grid, x, y, dist)
  return not isOutOfBounds(grid, x, y) and
    grid[y][x] == WALKABLE
end

-- returns grid units relative to the ui
local floor = math.floor
local function pxToGridUnits(screenX, screenY, gridSize, offX, offY)
  local gridPixelX, gridPixelY = screenX - (offX or 0), screenY - (offY or 0)
  local gridX, gridY =
    floor(gridPixelX / gridSize),
    floor(gridPixelY / gridSize)
  return gridX, gridY
end

local function getFlowFieldValue(flowField, gridX, gridY)
  local row = flowField[gridY]
  local v = row[gridX]
  if not v then
    return 0, 0, 0
  end
  return v[1], v[2], v[3]
end

local function drawPathWithAstar(ai)
  local self = ai
  local p = self.pathWithAstar
  local agentSilhouetteDrawQueue = {}
  local agentPathDrawQueue = {}

  for i=1, #p do
    local point = p[i]
    local x, y = (point.x) * gridSize,
      (point.y) * gridSize

    -- agent silhouette
    table.insert(
      agentSilhouetteDrawQueue,
      function()
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle(
          'fill',
          x, y,
          gridSize * 2,
          gridSize * 2
        )
      end
    )

    -- agent path
    table.insert(
      agentPathDrawQueue,
      function()
        love.graphics.setColor(0.6,0.7,0.0,0.5)
        love.graphics.rectangle(
          'fill',
          x, y,
          gridSize,
          gridSize
        )

        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i, x + 5, y + 5)
      end
    )
  end

  self.canvasAgentSilhouette = self.canvasAgentSilhouette or love.graphics.newCanvas()
  love.graphics.setCanvas(self.canvasAgentSilhouette)
  love.graphics.clear()
  for i=1, #agentSilhouetteDrawQueue do
    agentSilhouetteDrawQueue[i]()
  end
  love.graphics.setCanvas()
  love.graphics.setColor(1,1,1,0.3)
  -- need to translate canvas because parent scene is translated
  love.graphics.translate(-offX, 0)
  love.graphics.draw(self.canvasAgentSilhouette)
  love.graphics.translate(offX, 0)

  for i=1, #agentPathDrawQueue do
    agentPathDrawQueue[i]()
  end
end

function flowFieldTestBlueprint.init(self)
  local iterateGrid = require 'utils.iterate-grid'
  self.wallCollisions = {}
  iterateGrid(grid, function(v, x, y)
    if v ~= WALKABLE then
      self.wallCollisions[y] = self.wallCollisions[y] or {}
      self.wallCollisions[y][x] = collisionObject:new(
        'wall',
        (x * gridSize),
        (y * gridSize),
        gridSize, gridSize
      ):addToWorld(colWorld)
    end
  end)

  self.flowField = flowField(grid, 8, 5, isGridCellVisitable)
  local function findNearestTarget(otherX, otherY, otherSightRadius)
    if not self.targetPosition then
      return nil
    end

    local dist = Math.dist(self.targetPosition.x, self.targetPosition.y, otherX, otherY)
    local withinVision = dist <= otherSightRadius
    if withinVision then
      return self.targetPosition.x, self.targetPosition.y
    end

    return nil
  end

  local function AiFactory(x, y, speed, scale)
    return Ai.create({
      x = x * gridSize,
      y = y * gridSize,
      speed= speed,
      scale = scale,
      collisionWorld = colWorld,
      pxToGridUnits = pxToGridUnits,
      findNearestTarget = findNearestTarget,
      grid = grid,
      gridSize = gridSize,
      WALKABLE = WALKABLE,
      showAiPath = self.showAiPath
    })
  end

  self.ai = {
    AiFactory(2, 2, 240, 1.5):setParent(self),
    AiFactory(4, 2, 300, 1.2):setParent(self),
    -- put one that is stuck inside a wall to test automatic wall unstuck
    AiFactory(1, 6, 320, 1.1):setParent(self)
  }

  -- generate random ai agents
  local positionsFilled = {}
  while #self.ai <= 50 do
    local gridX = math.random(6, 20)
    local gridY = math.random(2, 20)
    local positionId = gridY * 20 + gridX

    if grid[gridY][gridX] == WALKABLE and not positionsFilled[positionId] then
      positionsFilled[positionId] = true
      table.insert(
        self.ai,
        AiFactory(gridX, gridY, 360, 0.5):setParent(self)
      )
    end
  end
end

function flowFieldTestBlueprint.update(self, dt)
  if love.mouse.isDown(1) or love.keyboard.isDown('space') then
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local gridX, gridY = pxToGridUnits(mx, my, gridSize, offX, offY)

    if isOutOfBounds(grid, gridX, gridY) then
      return
    end

    local gridValue = grid[gridY][gridX]
    if gridValue ~= WALKABLE then
      return
    end

    local ts = socket.gettime()
    self.targetPosition = {x = mx - offX, y = my - offY}
    self.flowField = flowField(grid, gridX, gridY, isGridCellVisitable)
    self.executionTimeMs = (socket.gettime() - ts) * 1000
  end

  f.forEach(self.ai, function(ai)
    ai._update2(ai, grid, self.flowField, dt)
  end)
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
local COLOR_ARROW = {0.7,0.7,0.7}
local COLOR_START_POINT = {0,1,0}

local function drawMousePosition()
  local gridX, gridY = pxToGridUnits(
    love.mouse.getX(),
    love.mouse.getY(),
    gridSize,
    offX,
    offY
  )
  love.graphics.setColor(1,1,0,1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle(
    'line',
    gridX * gridSize,
    gridY * gridSize,
    gridSize,
    gridSize
  )
end

local function drawScene(self)
  love.graphics.clear(0.1,0.1,0.1,1)

  local textDrawQueue = {}
  local arrowDrawQueue = {}

  for y=1, #grid do
    local row = self.flowField[y] or {}
    for x=1, #grid[1] do
      local cell = row[x]
      local drawX, drawY =
        (x * gridSize),
        (y * gridSize)

      local oData = grid[y][x]
      local ffd = row[x] -- flow field cell data
      local isStartPoint = ffd and (ffd.x == 0 and ffd.y == 0)
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
          love.graphics.setColor(COLOR_ARROW)
          if not isStartPoint then
            local rot = arrowRotationFromDirection(ffd.x, ffd.y)
            local offsetCenter = 8
            love.graphics.draw(
              arrow,
              drawX + gridSize / 2,
              drawY + gridSize / 2,
              rot,
              1,
              1,
              8,
              8
            )
          end
        end

        if self.showGridCoordinates then
          textDrawQueue[#textDrawQueue + 1] = function()
            love.graphics.setColor(0.5,0.8,0.5)
            love.graphics.scale(0.5)
            love.graphics.print(
              x..' '..y,
              drawX * 2 + 5,
              drawY * 2 + 6
            )
            love.graphics.scale(2)
          end
        end

        if self.showFlowFieldText then
          textDrawQueue[#textDrawQueue + 1] = function()
            love.graphics.scale(0.5)
            love.graphics.setColor(0.6,0.6,0.6,1)

            -- direction vectors
            love.graphics.print(
              row[x].x..' '..row[x].y,
              (drawX + 5) * 2,
              (drawY + 5) * 2
            )

            -- distance
            love.graphics.print(
              row[x].dist,
              (drawX + gridSize/2) * 2,
              (drawY + gridSize - 6) * 2
            )

            love.graphics.scale(2)
          end
        end
      end
    end
  end

  local function drawTitle()
    local offsetX = 50
    love.graphics.setColor(1,1,1,1)
    love.graphics.print('CLICK GRID TO SET CONVERGENCE POINT', 20 + offsetX, 20)

    if self.executionTimeMs ~= nil then
      love.graphics.setColor(0.5,0.5,0.5)
      love.graphics.print(
        string.format('execution time: %.4f(ms)', self.executionTimeMs),
        20 + offsetX,
        50
      )
    end
  end

  table.insert(textDrawQueue, drawTitle)

  for i=1, #arrowDrawQueue do
    arrowDrawQueue[i]()
  end

  for i=1, #textDrawQueue do
    textDrawQueue[i]()
  end

  if self.showAi then
    f.forEach(self.ai, function(ai)
      ai:draw(self.flowField, dt)
      if ai.showAiPath then
        drawPathWithAstar(ai)
      end
    end)
  end

  drawMousePosition()
end

function flowFieldTestBlueprint.draw(self)
  love.graphics.translate(offX, offY)
  drawScene(self)
  love.graphics.translate(-offX, -offY)
end

return Component.createFactory(flowFieldTestBlueprint)