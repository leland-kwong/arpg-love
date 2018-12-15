local Template = require 'repl.template'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local lightBlur = love.graphics.newImage('built/images/light-blur.png')

local options = {
  minDeviation = 10,
  maxDeviation = 30
}

local function generateLightning(x1, y1, x2, y2)
  local Position = require 'utils.position'
  local dx, dy = Position.getDirection(x1, y1, x2, y2)
  local firstSegmentDist = math.random(15, 18)
  local vertices = {
    x1, y1,
    x1 + firstSegmentDist * dx, y1 + firstSegmentDist * dy
  }

  -- vectors perpendicular to line
  local directions = {
    {-dy, dx},
    {dy, -dx}
  }
  local dirIndex = math.random(1, #directions)
  local Math = require 'utils.math'
  local totalDist = Math.dist(x1, y1, x2, y2)
  local lastSegmentDist = math.random(40, 120)
  local remainingDist = totalDist - firstSegmentDist - lastSegmentDist
  local nextDistIncrease = math.random(80, 90)
  local distTraveled = 0

  local function addVertice(dist)
    local length = math.random(options.minDeviation, options.maxDeviation)
    dirIndex = dirIndex == 1 and 2 or 1 -- alternate directions
    local dir = directions[dirIndex]
    local startX, startY = x1 + dx * dist, y1 + dy * dist
    local x, y = startX + dir[1] * length, startY + dir[2] * length
    table.insert(vertices, x)
    table.insert(vertices, y)
  end

  while (remainingDist > 0) do
    distTraveled = distTraveled + nextDistIncrease
    remainingDist = remainingDist - nextDistIncrease
    addVertice(distTraveled)
    nextDistIncrease = math.min(remainingDist, math.random(20, 150))
  end

  -- add last segment (the last segment's vector is same as original path)
  local segmentStartDist = lastSegmentDist/2
  table.insert(vertices, x2 - segmentStartDist * dx)
  table.insert(vertices, y2 - segmentStartDist * dy)
  table.insert(vertices, x2)
  table.insert(vertices, y2)

  return vertices
end

local colors = {
  -- {0.6,1,1},
  {1,1,1}
}

-- radius is in pixel units
local function lightSource(x, y, radius)
  local scale = (radius * 2) / lightBlur:getPixelWidth()
  love.graphics.draw(lightBlur, x - radius, y - radius, 0, scale, scale)
end

Component.create({
  id = 'lightning-generator-test',
  x = 350,
  y = 250,
  targetX = 600,
  targetY = 200,
  baseColor = {1.0, 1.0, 1.0},
  lightColor = {0, 0.7, 1},
  init = function(self)
    Component.addToGroup(self, 'gui')
    Template.create()

    self.clock = 0
    self.listeners = {
      msgBus.on(msgBus.MOUSE_DRAG, function(ev)
        self.targetX, self.targetY = ev.x, ev.y
      end)
    }
    self.stencil = function()
      love.graphics.line(self.vertices)
    end
  end,

  update = function(self, dt)
    self.clock = self.clock + dt
    local interval = 0.05
    if (self.clock > interval) then
      self.clock = 0
      self.vertices = generateLightning(
        self.x, self.y,
        self.targetX, self.targetY
      )
    end
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    local bgColor = {0.2,0.2,0.2}
    love.graphics.clear(bgColor)
    if self.vertices then
      local oBlendMode = love.graphics.getBlendMode()
      local Color = require 'modules.color'
      love.graphics.setLineWidth(3)
      love.graphics.setLineStyle('rough')

      love.graphics.setBlendMode('alpha')
      love.graphics.setColor(Color.multiplyAlpha(self.baseColor, 0.3))
      love.graphics.line(self.vertices)

      love.graphics.setBlendMode('add', 'alphamultiply')
      love.graphics.setColor(Color.multiplyAlpha(self.lightColor, 0.6))
      lightSource(self.x, self.y, 20)

      -- make stencil with lines
      love.graphics.stencil(self.stencil, 'replace', 1)
      love.graphics.setStencilTest('greater', 0)

      local oBlendMode = love.graphics.getBlendMode()
      love.graphics.setBlendMode('add', 'alphamultiply')
      love.graphics.setColor(Color.multiplyAlpha(self.lightColor, 0.9))
      for i=3, (#self.vertices - 2), 2 do
        local x, y = self.vertices[i], self.vertices[i + 1]
        lightSource(x, y, 60)
      end
      love.graphics.setStencilTest()

      love.graphics.setBlendMode(oBlendMode)
    end
    love.graphics.pop()
  end,

  drawOrder = function(self)
    return 100000
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})