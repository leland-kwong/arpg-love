local dynamicRequire = require 'utils.dynamic-require'
local Vec2 = require 'modules.brinevector'
local Color = require 'modules.color'
local Font = require 'components.font'
local Node = require 'utils.node-graph'
local AnimationFactory = dynamicRequire 'components.animation-factory'

local development = false

local graphColors = {
  region = {
    aureus = {Color.rgba255(44, 232, 245)},
    secret = {Color.rgba255(245, 98, 245)},
    saria = {Color.rgba255(254,174,52)},
    default = {0.5,0.5,0.5}
  },
  default = {Color.rgba255(44, 232, 245)},
  secret = {1,1,1,0},
  link = {1,1,1},
  linkLocked = {1,1,1,0.25}
}

local function renderNode(nodeId, distScale, state)
  love.graphics.setColor(0,1,1)
  local ref = Node:get(nodeId)
  local p = ref.position * distScale
  local unlocked = state.unlockedNodes[nodeId]
  local c
  if unlocked then
    c = graphColors.region[ref.region] or
      (ref.secret and graphColors.region.secret) or
      graphColors.region.default
  else
    c = Color.LIME
  end
  love.graphics.setColor(c)
  local graphic = unlocked and
    AnimationFactory:newStaticSprite('gui-map-portal-point') or
    AnimationFactory:newStaticSprite('gui-map-portal-point-locked')
  local scale = state.nodeStyles[nodeId].scale
  graphic:draw(p.x + 0.5, p.y + 0.5, 0, scale, scale)
end

local T = love.graphics.newText(Font.primary.font, '')
local function getTextSize(text, font, wrapLimit, align)
  T:setFont(font)
  if wrapLimit then
    T:setf(text, wrapLimit, align or 'left')
    return T:getWidth(), T:getHeight()
  end
  local oLineHeight = font:getLineHeight()
  font:setLineHeight(0.9)
  T:set(text)
  font:setLineHeight(oLineHeight)
  return T:getWidth(), T:getHeight()
end

local labelOffsets = {
  top = function(textW, textH)
    return Vec2(-textW/2, -25)
  end,
  right = function(textW, textH)
    return Vec2(15, -textH/2)
  end,
  bottom = function(textW, textH)
    return Vec2(-textW/2, -30)
  end,
  left = function(textW, textH)
    return Vec2(-textW - 15, -textH/2)
  end
}
local function renderNodeLabel(nodeId, distScale, cameraScale, labelFont)
  local opacity = distScale - 1
  local c = 0.9
  love.graphics.setColor(c,c,c,opacity)
  local ref = Node:get(nodeId)
  local label = ref.level
  local position = (ref.position * distScale)
  if label then
    love.graphics.setFont(labelFont)
    local humanizedLabel = string.gsub(label, '_', ' ')
    local textW, textH = getTextSize(humanizedLabel, labelFont)
    local lOffset = labelOffsets[ref.labelPosition] or labelOffsets.top
    local p = position + lOffset(textW, textH)
    love.graphics.print(humanizedLabel, p.x, p.y)
  end

  if development then
    love.graphics.push()
    love.graphics.origin()

    love.graphics.setColor(1,1,0)
    love.graphics.setFont(Font.primaryLarge.font)

    local p = position * cameraScale
    love.graphics.print(nodeId, p.x, p.y + 42)

    love.graphics.pop()
  end
end

local function renderRegionLabel(position, distScale, label, labelFont)
  love.graphics.setFont(labelFont)
  local labelWidth, labelHeight = getTextSize(label, labelFont)
  love.graphics.setColor(1,1,1)
  local offset = Vec2(-labelWidth/2, -labelHeight - 40)
  local scaleDiff = (distScale < 2) and (2 - distScale) or 0
  local p = (position * (distScale + scaleDiff)) + offset
  love.graphics.push()
  love.graphics.scale(math.min(1, distScale/2))
  love.graphics.translate(p.x, p.y)
  love.graphics.print(label)
  love.graphics.pop()
end

local function renderLink(node1, node2, distScale, state)
  local ref1, ref2 = Node:get(node1),
    Node:get(node2)
  local p1, p2 = ref1.position * distScale, ref2.position * distScale
  local c = graphColors.link
  local isUnAccessible = (not state.unlockedNodes[node1]) and (not state.unlockedNodes[node2])
  local hasLocked = (not state.unlockedNodes[node1]) or (not state.unlockedNodes[node2])
  local isSecret = (ref1.secret or ref2.secret)
  if isUnAccessible then
    if isSecret then
      c = graphColors.secret
    else
      c = graphColors.linkLocked
    end
  elseif hasLocked and isSecret then
    c = graphColors.secret
  end
  love.graphics.setColor(c)
  love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

local renderCanvas = love.graphics.newCanvas(4096, 4096)
return function(graph, cameraScale, distScale, state, isDevelopment)
  development = isDevelopment

  local nodesToRender = {}
  local nodesByRegion = {
    regions = {},
    add = function(self, region, node)
      self.regions[region] = self.regions[region] or {}
      table.insert(self.regions[region], node)
    end
  }
  love.graphics.push()
  love.graphics.origin()
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.setCanvas(renderCanvas)
  love.graphics.clear()
  love.graphics.setLineStyle('rough')

  graph:forEach(function(link)
    local node1, node2 = link[1], link[2]
    if (not nodesToRender[node1]) then
      nodesByRegion:add(Node:get(node1).region, node1)
    end
    nodesToRender[node1] = node1

    if (not nodesToRender[node2]) then
      nodesByRegion:add(Node:get(node2).region, node2)
    end
    nodesToRender[node2] = node2
    renderLink(node1, node2, distScale, state)
  end)

  love.graphics.setCanvas()
  love.graphics.pop()
  love.graphics.setColor(1,1,1)
  love.graphics.setBlendMode(oBlendMode)

  local lineGapStencil = function()
    love.graphics.setColor(1,1,1)
    local clamp = require 'utils.math'.clamp
    local radius = clamp(14 * distScale/2, 12, 14)
    for nodeId in pairs(nodesToRender) do
      local ref = Node:get(nodeId)
      local p = ref.position * distScale
      love.graphics.circle('fill', p.x, p.y, radius)
    end
  end
  love.graphics.stencil(lineGapStencil, 'replace', 1)

  love.graphics.setStencilTest('notequal', 1)
  love.graphics.draw(renderCanvas)
  love.graphics.setStencilTest()

  love.graphics.setLineWidth(1)
  for nodeId in pairs(nodesToRender) do
    renderNode(nodeId, distScale, state)
  end

  local oFont = love.graphics.getFont()
  local labelFont = Font.secondary.font
  love.graphics.setFont(labelFont)
  for nodeId in pairs(nodesToRender) do
    renderNodeLabel(nodeId, distScale, cameraScale, labelFont)
  end
  love.graphics.setFont(oFont)

  for region in pairs(nodesByRegion.regions) do
    local nodes = nodesByRegion.regions[region]
    local x, xTotal, y = 0, 0, nil
    for i=1, #nodes do
      local ref = Node:get(nodes[i])
      local p = ref.position
      xTotal = xTotal + p.x
      x = xTotal/i
      y = y or p.y
      y = math.min(y, p.y)
    end
    renderRegionLabel(Vec2(x, y), distScale, region, Font.secondaryLarge.font)
  end
end