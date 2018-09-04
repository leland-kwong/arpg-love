local Component = require 'modules.component'
local socket = require 'socket'
local pprint = require 'utils.pprint'
local memoize = require 'utils.memoize'
local FlowField = require 'modules.flow-field.flow-field'
local grid = require 'scene.sandbox.ai.grid'
local groups = require 'components.groups'
local collisionObject = require 'modules.collision'
local bump = require 'modules.bump'
local arrow = love.graphics.newImage('scene/sandbox/ai/arrow-up.png')
local f = require'utils.functional'
local Ai = require'components.ai.ai'
local Math = require'utils.math'

local gridSize = 32
local WALKABLE = 0
local agentCount = 50
local maxFlowFieldDistance = 30
local colWorld = bump.newWorld(gridSize)
local aiTestGroup = groups.hud
local function isGridCellVisitable(grid, x, y, dist)
  return grid[y][x] == WALKABLE and
    dist < maxFlowFieldDistance
end
local flowField = FlowField(isGridCellVisitable)

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

local flowFieldTestBlueprint = {
  group = aiTestGroup,
  -- debug = true,
  -- showFlowFieldText = true,
  -- showGridCoordinates = true,
  -- showAiPath = true,
  -- drawSubFlowFields = true,
  showAi = true,
  showFlowFieldArrows = true,
  drawOrder = function()
    return 2
  end
}


local function isOutOfBounds(grid, x, y)
  return y < 1 or x < 1 or y > #grid or x > #grid[1]
end

-- returns grid units relative to the ui
local round = Math.round
local function pxToGridUnits(pixelX, pixelY, gridSize)
  local gridX, gridY =
    round(pixelX / gridSize),
    round(pixelY / gridSize)
  return gridX, gridY
end

function flowFieldTestBlueprint.init(self)
  local parent = self

  self.getMainFlowField = FlowField(function (grid, x, y, dist)
    local row = grid[y]
    local cell = row and row[x]
    return
      (cell == WALKABLE) and
      (dist < maxFlowFieldDistance)
  end)

  local DirectionalFlowFields = require 'modules.flow-field.directional-flow-fields'
  self.subFlowFields = DirectionalFlowFields(function()
    return pxToGridUnits(parent.targetPosition.x, parent.targetPosition.y, gridSize)
  end, WALKABLE)

  local iterateGrid = require 'utils.iterate-grid'
  self.wallCollisions = {}
  iterateGrid(grid, function(v, x, y)
    if v ~= WALKABLE then
      self.wallCollisions[y] = self.wallCollisions[y] or {}
      self.wallCollisions[y][x] = self:addCollisionObject(
        'obstacle',
        (x * gridSize),
        (y * gridSize),
        gridSize, gridSize
      ):addToWorld(colWorld)
    end
  end)

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

  local function AiFactory(x, y, speed, scale, attackRange)
    local AnimationFactory = require 'components.animation-factory'
    return Ai.create({
      group = aiTestGroup,
      silenced = true,
      -- debug = true,
      x = x * gridSize,
      y = y * gridSize,
      speed = speed,
      scale = scale,
      collisionWorld = colWorld,
      pxToGridUnits = pxToGridUnits,
      findNearestTarget = findNearestTarget,
      attackRange = attackRange,
      grid = grid,
      gridSize = gridSize,
      WALKABLE = WALKABLE,
      showAiPath = self.showAiPath,
      animations = {
        idle = AnimationFactory:new({'pixel-white-1x1'}),
        moving = AnimationFactory:new({'pixel-white-1x1'})
      },
      w = 32,
      h = 32,
      getPlayerRef = function()
        return self.dummyPlayer
      end,
      sightRadius = 40,
      draw = function(self)
        local scale = self.scale
        local w, h = self.w * scale, self.h * scale
        local alpha = 0.6
        if not self.isFinishedMoving then
          love.graphics.setColor(1,0.2,1,alpha)
        else
          love.graphics.setColor(0,0.8,0, alpha)
        end
        love.graphics.rectangle('fill', self.x, self.y, w, h)

        -- border
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', self.x, self.y, w, h)

        -- local arrowRotation = arrowRotationFromDirection(self.direction.x, self.direction.y)
        -- love.graphics.setColor(1,1,1)
        -- love.graphics.draw(
        --   arrow,
        --   self.x + w/2,
        --   self.y + h/2,
        --   arrowRotation,
        --   1,
        --   1,
        --   8,
        --   8
        -- )

        -- local path = self.pathWithAstar
        -- if path then
        --   for i=1, #path do
        --     local position = path[i]
        --     love.graphics.setLineWidth(2)
        --     love.graphics.setColor(1,1,1)
        --     love.graphics.rectangle(
        --       'line',
        --       position.x * gridSize,
        --       position.y * gridSize,
        --       gridSize,
        --       gridSize
        --     )
        --   end
        -- end
      end,
      drawOrder = function(self)
        return 5
      end
    })
  end

  self.ai = {
    -- AiFactory(2, 2, 240, 1.5):setParent(self),
    -- AiFactory(4, 2, 300, 1.2):setParent(self),
    -- -- put one that is stuck inside a wall to test automatic wall unstuck
    -- AiFactory(1, 6, 320, 1.1):setParent(self)
  }

  -- generate random ai agents
  local positionsFilled = {}
  local function generateScale(scale)
    local isScaleInteger = scale % 1 == 0
    if (isScaleInteger) then
      -- prevent agents of scale that are on whole integers since that will cause the
      -- collision detection to get stuck on walls for larger agents.
      return scale - 0.1
    end
    return scale
  end
  while #self.ai < agentCount do
    local gridX = math.random(10, 20)
    local gridY = math.random(10, 20)
    local positionId = gridY * 20 + gridX

    if grid[gridY][gridX] == WALKABLE and not positionsFilled[positionId] then
      positionsFilled[positionId] = true
      local scale = generateScale(math.random(1, 2))
      local attackRange = math.random(2, 6)
      local speed = 350/scale
      table.insert(
        self.ai,
        AiFactory(gridX, gridY, speed, scale, attackRange):setParent(self)
      )
    end
  end

  self.dummyPlayer = Component.createFactory({
    group = aiTestGroup,
    x = 0,
    y = 0,
    w = 16,
    h = 16,
    id = 'TEST_PLAYER',
  }).create()

  local genericNode = Component.createFactory({
    group = aiTestGroup
  })
  genericNode.create({
    draw = function()
      love.graphics.push()
      love.graphics.origin()
    end,
    drawOrder = function()
      return 1
    end
  })

  genericNode.create({
    draw = function()
      love.graphics.pop()
    end,
    drawOrder = function()
      return 1000
    end
  })
end

local function generateFlowField(self, dt)
  local mx, my = love.mouse.getX(), love.mouse.getY()
  local gridX, gridY = pxToGridUnits(mx, my, gridSize)

  if isOutOfBounds(grid, gridX, gridY) then
    return
  end

  local gridValue = grid[gridY][gridX]
  if gridValue ~= WALKABLE then
    return
  end

  local ts = socket.gettime()
  self.dummyPlayer:setPosition(mx, my)
  self.targetPosition = {
    x = self.dummyPlayer:getProp('x'),
    y = self.dummyPlayer:getProp('y')
  }

  self.mainFlowField = self.getMainFlowField(grid, gridX, gridY)

  local executionTimeMs = (socket.gettime() - ts) * 1000
  self.callCount = (self.callCount or 0) + 1
  self.totalExecutionTime = (self.totalExecutionTime or 0) + executionTimeMs
  self.executionTimeMs = self.totalExecutionTime / self.callCount
end

function flowFieldTestBlueprint.update(self, dt)
  if love.mouse.isDown(1) then
    generateFlowField(self, dt)
  end

  if self.subFlowFields then
    local fieldIndex = 1
    f.forEach(self.ai, function(ai)
      local flowFieldToUse = self.mainFlowField
      ai._update2(ai, grid, flowFieldToUse, dt)
    end)
  end
end

local COLOR_UNWALKABLE = {0.2,0.2,0.2,1}
local COLOR_WALKABLE = {0.2,0.35,0.55,1}
local COLOR_ARROW = {1,1,1,0.3}
local COLOR_START_POINT = {0,1,0}

local function drawMousePosition()
  local gridX, gridY = pxToGridUnits(
    love.mouse.getX(),
    love.mouse.getY(),
    gridSize
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

local function drawFlowFields(self)
  if not self.subFlowFields then
    return
  end
  love.graphics.setColor(0.8,1,0.2,0.8)
  local iterateGrid = require 'utils.iterate-grid'
  love.graphics.setColor(1,1,0)
  iterateGrid(self.subFlowFields[1], function(v, x, y)
    if not v then
      return
    end
    local rotation = arrowRotationFromDirection(v.x, v.y)
    love.graphics.draw(
      arrow,
      x * gridSize + self.targetPosition.x - 15 * gridSize,
      y * gridSize + self.targetPosition.y - 15 * gridSize,
      rotation,
      1, 1,
      8,
      8
    )
  end)
end

local function drawMainFlowField(self, arrowDrawQueue, textDrawQueue)
  if not self.mainFlowField then
    return
  end
  for y=1, #grid do
    local row = self.mainFlowField[y] or {}
    for x=1, #grid[1] do
      local cell = row[x]
      local drawX, drawY =
        (x * gridSize),
        (y * gridSize)

      local oData = grid[y][x]
      local ffd = row[x] -- flow field cell data
      love.graphics.setColor(
        oData == WALKABLE and
          COLOR_WALKABLE or
          COLOR_UNWALKABLE
      )

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
        if self.showFlowFieldArrows then
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
            love.graphics.setColor(0,1,0.6,1)

            -- direction vectors
            love.graphics.print(
              row[x].x..' '..row[x].y,
              (drawX + 5) * 2,
              (drawY + 4) * 2
            )

            -- distance
            love.graphics.print(
              row[x].dist,
              (drawX + gridSize/2) * 2,
              (drawY + gridSize - 7) * 2
            )

            love.graphics.scale(2)
          end
        end
      end
    end
  end
end

local function drawScene(self)
  love.graphics.clear(0.1,0.1,0.1,1)

  local textDrawQueue = {}
  local arrowDrawQueue = {}

  drawMainFlowField(self, arrowDrawQueue, textDrawQueue)
  if self.drawSubFlowFields then
    drawFlowFields(self)
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
      -- ai:draw(self.flowField, dt)
      if ai.showAiPath then
        drawPathWithAstar(ai)
      end
    end)
  end

  drawMousePosition()
end

function flowFieldTestBlueprint.draw(self)
  drawScene(self)

  if self.targetPosition then
    love.graphics.print(
      'mousePosition: '..self.targetPosition.x..','..self.targetPosition.y,
      love.graphics.getWidth() - 300,
      5
    )
  end
end

return Component.createFactory(flowFieldTestBlueprint)