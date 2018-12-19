local Component = require 'modules.component'
local lightBlur = love.graphics.newImage('built/images/light-blur.png')
local Vec2 = require 'modules.brinevector'
local moonshine = require 'modules.moonshine'

local glowEffect = moonshine(
  moonshine.effects.glow
)

glowEffect.glow.strength = 5
glowEffect.glow.min_luma = 0.0

local options = {
  minDeviation = 5,
  maxDeviation = 10
}

local function generateLightning(startPt, target)
  local Position = require 'utils.position'
  local Math = require 'utils.math'

  local x1, y1, x2, y2 = startPt.x, startPt.y, target.x, target.y
  local totalDist = Math.dist(x1, y1, x2, y2)
  local dx, dy = Position.getDirection(x1, y1, x2, y2)
  local firstSegmentDist = math.min(totalDist, math.random(5, 18))
  local vertices = {
    x1, y1,
    x1 + firstSegmentDist * dx, y1 + firstSegmentDist * dy
  }

  local isSingleSegment = totalDist == firstSegmentDist
  if isSingleSegment then
    return vertices
  end

  -- vectors perpendicular to line
  local directions = {
    {-dy, dx},
    {dy, -dx}
  }
  local remainingDist = totalDist - firstSegmentDist
  local dirIndex = math.random(1, #directions)
  local lastSegmentDist = math.min(remainingDist, math.random(5, 50))
  remainingDist = remainingDist - lastSegmentDist

  local function addVertice(dist)
    local length = math.random(options.minDeviation, options.maxDeviation)
    dirIndex = dirIndex == 1 and 2 or 1
    -- dirIndex = math.random(1, #directions)
    local dir = directions[dirIndex]
    local startX, startY = x1 + dx * dist, y1 + dy * dist
    local x, y = startX + dir[1] * length, startY + dir[2] * length
    table.insert(vertices, x)
    table.insert(vertices, y)
  end

  local distTraveled = 0
  local nextDistIncrease = 0
  while (remainingDist > 0) do
    nextDistIncrease = math.min(remainingDist, math.random(15, 50))
    distTraveled = distTraveled + nextDistIncrease
    remainingDist = remainingDist - nextDistIncrease
    addVertice(distTraveled)
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

local addParamsMt = {
  start = Vec2(0,0),
  target = Vec2(10, 10),
  duration = 0.4,
  opacity = 1,

  color = {0.4, 0.8, 1},
  thickness = 2,
  targetPointRadius = 4
}
addParamsMt.__index = addParamsMt
local instanceTweenTarget = {opacity = 0}

return Component.create({
  id = 'lightning-effect',
  init = function(self)
    Component.addToGroup(self, 'all')

    self.stencil = function()
      for i=1, #self.sources do
        local s= self.sources[i]
        love.graphics.line(s.vertices)
      end
    end
    self.canvas = love.graphics.newCanvas()
    self.sources = {}
  end,

  add = function(self, params)
    local instance = setmetatable(params, addParamsMt)
    instance.vertices = generateLightning(
      params.start,
      params.target
    )
    local tween = require 'modules.tween'
    instance.tween = tween.new(params.duration, instance, instanceTweenTarget, tween.easing.inQuad)
    table.insert(
      self.sources,
      instance
    )
    return self
  end,

  update = function(self, dt)
    local i = 1
    while i <= #self.sources do
      local s = self.sources[i]
      local complete = s.tween:update(dt)
      if complete then
        table.remove(self.sources, i)
      else
        i = i + 1
      end
    end
  end,

  draw = function(self)
    if #self.sources > 0 then
      love.graphics.setCanvas{self.canvas, stencil=true}
      love.graphics.clear()

      local oBlendMode = love.graphics.getBlendMode()
      local Color = require 'modules.color'

      -- draw base lines
      for i=1, #self.sources do
        local source = self.sources[i]
        love.graphics.setLineStyle('rough')

        love.graphics.setLineWidth(source.thickness)
        love.graphics.setBlendMode('alpha')
        love.graphics.setColor(Color.multiplyAlpha(source.color, 0.35 * source.opacity))
        love.graphics.line(source.vertices)
      end

      love.graphics.setBlendMode('add', 'alphamultiply')
      for i=1, #self.sources do
        local source = self.sources[i]
        love.graphics.setColor(Color.multiplyAlpha(source.color, 0.8 * source.opacity))

        -- start point light
        lightSource(source.start.x, source.start.y, source.thickness * 8)

        -- end point light
        local lastVertice = #source.vertices - 1
        love.graphics.setColor(Color.multiplyAlpha(source.color, 0.8 * source.opacity))
        lightSource(
          source.vertices[lastVertice],
          source.vertices[lastVertice + 1],
          source.thickness * source.targetPointRadius
        )
      end

      --[[ post-processing ]]

      -- add a gradient effect on points
      love.graphics.stencil(self.stencil, 'replace', 1)
      love.graphics.setStencilTest('greater', 0)
      love.graphics.setBlendMode('add', 'alphamultiply')
      for i=1, #self.sources do
        local source = self.sources[i]
        local vertices = source.vertices
        love.graphics.setColor(Color.multiplyAlpha(source.color, 0.9 * source.opacity))
        for i=3, (#vertices), 2 do
          local x, y = vertices[i], vertices[i + 1]
          lightSource(x, y, math.random(40, 70))
        end
      end

      love.graphics.setStencilTest()

      love.graphics.setCanvas()

      love.graphics.setColor(1,1,1)
      love.graphics.setBlendMode('alpha', 'premultiplied')
      love.graphics.push()
      love.graphics.origin()
      glowEffect(function()
        love.graphics.draw(self.canvas)
      end)
      love.graphics.pop()
      love.graphics.setBlendMode(oBlendMode)
    end
  end,

  drawOrder = function(self)
    return Component.get('PLAYER'):drawOrder() + 1
  end
})