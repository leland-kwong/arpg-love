local socket = require 'socket'
local pprint = require 'utils.pprint'
local memoize = require 'utils.memoize'
local flowField = require 'scene.sandbox.ai.flow-field'
local grid = require 'scene.sandbox.ai.grid'
local groups = require 'components.groups'
local collisionObject = require 'modules.collision'
local bump = require 'modules.bump'
local tween = require 'modules.tween'
local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')
local f = require'utils.functional'

local gridSize = 32
local offX, offY = 100, 0
local WALKABLE = 0

local flowFieldTestBlueprint = {
  showFlowFieldText = false,
  showGridCoordinates = true,
  showAiPath = false
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
local function pxToGridUnits(screenX, screenY, offX, offY)
  local gridPixelX, gridPixelY = screenX - (offX or 0), screenY - (offY or 0)
  local gridX, gridY =
    math.floor(gridPixelX / gridSize),
    math.floor(gridPixelY / gridSize)
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

local Ai = {}
local Ai_mt = {__index = Ai}

local function isZeroVector(vx, vy)
  return vx == 0 and vy == 0
end

-- gets directions from grid position, adjusting vectors to handle wall collisions as needed
local normalize = require'utils.position'.normalizeVector
local aiPathWithAstar = require'scene.sandbox.ai.pathing-with-astar'
Ai.getPathWithAstar = require'utils.perf'({
  enabled = false,
  done = function(t)
    print('ai path:', t)
  end
})(aiPathWithAstar)

function Ai:move(flowField, dt)
  local centerOffset = self.padding
  local isNewPath = self.collided or self.lastFlowField ~= flowField
  self.collided = false

  if isNewPath then
    local actualX, actualY = self.x, self.y
    local gridX, gridY = pxToGridUnits(self.x, self.y)
    self.pathWithAstar = self:getPathWithAstar(flowField, grid, gridX, gridY, 30, WALKABLE, self.scale)

    local index = 1
    local path = self.pathWithAstar
    local posTween
    local done = true
    self.positionTweener = function(dt)
      if done then
        if index > #path then
          return
        end
        local nextPos = {
          x = (path[index].x) * gridSize + centerOffset,
          y = (path[index].y) * gridSize + centerOffset
        }
        local dist = require'utils.math'.dist(self.x, self.y, nextPos.x, nextPos.y)
        local duration = dist / self.speed
        posTween = tween.new(duration, self, nextPos)
        index = index + 1
      end
      done = posTween:update(dt)
    end
  end

  self.positionTweener(dt)
  local nextX, nextY = self.x, self.y
  local adjustedX, adjustedY, cols, len = self.collision:move(nextX, nextY)

  self.x = adjustedX
  self.y = adjustedY
  self.collided = len > 0
  self.lastFlowField = flowField
end

local perf = require'utils.perf'
local drawSmoothenedPath = perf({
  enabled = false,
  done = function(t)
    print('bezier curve:', t)
  end
})(function(path)
  -- bezier curve must have at least 2 points
  if #path < 2 then
    return
  end

  -- draw path curve
  local curve = love.math.newBezierCurve(
    f.reduce(path, function(points, v)
      points[#points + 1] = (v.x) * gridSize
      points[#points + 1] = (v.y) * gridSize
      return points
    end, {})
  )

  -- simulating many ops
  -- for i=1, 50 do
  --   love.math.newBezierCurve(
  --     f.reduce(path, function(points, v)
  --       points[#points + 1] = v.x * gridSize + i
  --       points[#points + 1] = v.y * gridSize + i
  --       return points
  --     end, {})
  --   )
  -- end

  local curveCoords = curve:render(2)
  love.graphics.setLineWidth(4)
  love.graphics.setColor(0.5,0.8,1,1)
  love.graphics.line(curveCoords)
end)

local function drawPathWithAstar(self)
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

  drawSmoothenedPath(p)
end

function Ai:draw()
  love.graphics.setColor(1,0.2,0, 0.8)
  local padding = 0
  love.graphics.rectangle(
    'fill',
    self.x + padding,
    self.y + padding,
    self.w - padding * 2,
    self.h - padding * 2
  )

  -- collision shape
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle(
    'line',
    self.collision.x + self.collision.ox,
    self.collision.y + self.collision.oy,
    self.collision.h,
    self.collision.w
  )

  if self.showAiPath then
    drawPathWithAstar(self)
  end
end

local function createAi(x, y, speed, scale, showAiPath)
  if scale % 1 == 0 then
    -- to prevent wall collision from getting stuck when pathing around corners, we'll adjust
    -- the agent size so its slightly smaller than the grid size.
    scale = scale - (2 / gridSize)
  end

  local scale = scale or 1
  local size = gridSize * scale
  --[[
    Padding is the difference between the full grid size and the actual rectangle size.
    Ie: if scale is 1.5, then the difference is (2 - 1.5) * gridSize
  ]]
  local padding = math.ceil(scale) * gridSize - size
  local w, h = size, size
  local colObj = collisionObject
    :new('ai', x, y, w, h)
    :addToWorld(colWorld)
  return setmetatable({
    x = x,
    y = y,
    w = w,
    h = h,
    -- used for centering the agent during movement
    padding = math.ceil(padding / 2),
    dx = 0,
    dy = 0,
    scale = scale,
    speed = speed or 100,
    collision = colObj,
    showAiPath = showAiPath
  }, Ai_mt)
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
  self.ai = {
    createAi(
      2 * gridSize,
      2 * gridSize,
      240,
      1.5,
      self.showAiPath
    ),
    createAi(
      4 * gridSize,
      2 * gridSize,
      300,
      1.2,
      self.showAiPath
    )
  }

  local positionsFilled = {}
  while #self.ai <= 70 do
    local gridX = math.random(6, 20)
    local gridY = math.random(2, 20)
    local positionId = gridY * 20 + gridX

    if grid[gridY][gridX] == WALKABLE and not positionsFilled[positionId] then
      positionsFilled[positionId] = true
      table.insert(
        self.ai,
        createAi(
          gridX * gridSize,
          gridY * gridSize,
          360,
          0.7,
          self.showAiPath
        )
      )
    end
  end
end

function flowFieldTestBlueprint.update(self, dt)
  if love.mouse.isDown(1) or love.keyboard.isDown('space') then
    local mx, my = love.mouse.getX(), love.mouse.getY()
    local gridX, gridY = pxToGridUnits(mx, my, offX, offY)

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

  f.forEach(self.ai, function(ai)
    ai:move(self.flowField, dt)
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

  f.forEach(self.ai, function(ai)
    ai:draw(self.flowField, dt)
  end)
  drawMousePosition()
end

function flowFieldTestBlueprint.draw(self)
  love.graphics.translate(offX, offY)
  drawScene(self)
  love.graphics.translate(-offX, -offY)
end

return groups.gui.createFactory(flowFieldTestBlueprint)