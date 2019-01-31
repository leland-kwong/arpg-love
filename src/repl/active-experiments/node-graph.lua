local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Gui = require 'components.gui.gui'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'
local Grid = require 'utils.grid'
local Color = require 'modules.color'
local Font = require 'components.font'
local getTextSize = require 'repl.libs.get-text-size'

local state = {
  distScale = 2
}

local nodeMt = {
  position = Vec2()
}
local modelMt = {
  addLink = function(self, node1, node2)
    Grid.set(self.links, node1, node2, true)
    return self
  end,

  removeLink = function(self, link)
    Grid.set(self.links, link[1], link[2], nil)
    return self
  end,

  forEach = function(self, callback)
    Grid.forEach(self.links, callback)
    return self
  end
}
modelMt.__index = modelMt
local modelDefaultOptions = {
  validator = function(self, node1, node2)
    return true
  end
}

local Node = {
  counter = 0,
  nodeList = {},
  -- returns an id for the node
  create = function(self, props)
    local node = setmetatable(props, nodeMt)
    self.counter = self.counter + 1
    local id = node.id or self.counter
    node.id = id
    self.nodeList[id] = node
    return id
  end,
  createModel = function(self, options)
    return setmetatable({
      links = {}
    }, modelMt)
  end,
  get = function(self, id)
    return self.nodeList[id]
  end,
  delete = function(self, id)
    self.nodeList[id] = nil
    return self
  end,
  reduce = function(self, reducer, seed)
    local i = 1
    for id in pairs(self.nodeList) do
      seed = reducer(seed, id, i)
      i = i + 1
    end
    return seed
  end
}

local graphColors = {
  region = {
    aureus = {Color.rgba255(44, 232, 245)},
    secret = {Color.rgba255(245, 98, 245)},
    saria = {Color.rgba255(254,174,52)},
    default = {0.5,0.5,0.5}
  },
  default = {Color.rgba255(44, 232, 245)},
  secret = {1,1,1,0},
  link = {1,1,1}
}

local function renderNode(nodeId, distScale)
  love.graphics.setColor(0,1,1)
  local ref = Node:get(nodeId)
  local p = ref.position * distScale
  local c = graphColors.region[ref.region] or
    (ref.secret and graphColors.region.secret) or
    graphColors.region.default
  love.graphics.setColor(c)
  love.graphics.circle('fill', p.x, p.y, 3)

  love.graphics.setColor(Color.multiplyAlpha(c, 0.3))
  love.graphics.circle('line', p.x, p.y, 9)
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
local function renderNodeLabel(nodeId, distScale, labelFont)
  local opacity = distScale - 1
  local c = 0.9
  love.graphics.setColor(c,c,c,opacity)
  local ref = Node:get(nodeId)
  local label = ref.level
  if label then
    local humanizedLabel = string.gsub(label, '_', ' ')
    local textW, textH = getTextSize(humanizedLabel, labelFont)
    local lOffset = labelOffsets[ref.labelPosition] or labelOffsets.top
    local p = (ref.position * distScale) + lOffset(textW, textH)
    love.graphics.print(humanizedLabel, p.x, p.y)
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

local function renderLink(node1, node2, distScale)
  local ref1, ref2 = Node:get(node1),
    Node:get(node2)
  local p1, p2 = ref1.position * distScale, ref2.position * distScale
  love.graphics.setColor(
    (ref1.secret or ref2.secret) and
      graphColors.secret or
      graphColors.link
  )
  love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

local createUniverse = function()
  local model = Node:createModel()

  local level1 = Node:create({
    position = Vec2(20, 20),
    region = 'aureus',
    level = 'floor_1',
    labelPosition = 'top'
  })

  local level2 = Node:create({
    position = Vec2(
      Node:get(level1).position.x + 40,
      Node:get(level1).position.y
    ),
    region = 'aureus',
    level = 'floor_2',
    labelPosition = 'top'
  })
  model:addLink(level2, level1)

  local level3 = Node:create({
    position = Vec2(
      Node:get(level2).position.x + 50,
      Node:get(level2).position.y + 20
    ),
    level = 's-1',
    region = 'saria'
  })
  model:addLink(level3, level2)

  local level4 = Node:create({
    position = Vec2(
      Node:get(level3).position.x + 30,
      Node:get(level3).position.y
    ),
    level = 's-2',
    region = 'saria'
  })
  model:addLink(level4, level3)

  local level5 = Node:create({
    position = Vec2(
      Node:get(level4).position.x + 15,
      Node:get(level4).position.y + 25
    ),
    level = 's-3',
    labelPosition = 'right',
    region = 'saria'
  })
  model:addLink(level5, level4)

  local level6 = Node:create({
    position = Vec2(
      Node:get(level4).position.x - 15,
      Node:get(level4).position.y + 25
    ),
    level = 's-4',
    labelPosition = 'left',
    region = 'saria'
  })
  model:addLink(level6, level4)

  local avgPos = (Node:get(level2).position + Node:get(level3).position) / 2
  local secretLevel1 = Node:create({
    position = Vec2(
      avgPos.x - 15,
      avgPos.y + 20
    ),
    secret = true,
    region = ''
  })
  model:addLink(secretLevel1, level2)

  local avgPos = (Node:get(level2).position + Node:get(level4).position) / 2
  local secretLevel2 = Node:create({
    position = Vec2(
      avgPos.x + 6,
      avgPos.y - 25
    ),
    secret = true,
    region = ''
  })
  model:addLink(secretLevel2, level4)

  return model
end

local renderCanvas = love.graphics.newCanvas(4096, 4096)
local renderGraph = function(graph, distScale)
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

  graph:forEach(function(_, node1, node2)
    if (not nodesToRender[node1]) then
      nodesByRegion:add(Node:get(node1).region, node1)
    end
    nodesToRender[node1] = node1

    if (not nodesToRender[node2]) then
      nodesByRegion:add(Node:get(node2).region, node2)
    end
    nodesToRender[node2] = node2
    renderLink(node1, node2, distScale)
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
    renderNode(nodeId, distScale)
  end

  local oFont = love.graphics.getFont()
  local labelFont = Font.secondary.font
  love.graphics.setFont(labelFont)
  for nodeId in pairs(nodesToRender) do
    renderNodeLabel(nodeId, distScale, labelFont)
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

Component.create({
  id = 'WorldEditor',
  group = 'hud',
  init = function(self)
    local mainMenuRef = Component.get('mainMenu')
    if mainMenuRef then
      msgBus.send('TOGGLE_MAIN_MENU', false)
      mainMenuRef:delete(true)
    end

    local homeScreenRef = Component.get('HomeScreen')
  if homeScreenRef then
      homeScreenRef:delete(true)
    end

    Gui.create({
      x = 0,
      y = 0,
      w = love.graphics.getWidth(),
      h = love.graphics.getHeight(),
      onWheel = function(self, ev)
        local dy = ev[2]
        local clamp = require 'utils.math'.clamp
        local round = require 'utils.math'.round
        Component.animate(state, {
          distScale = clamp(round(state.distScale + dy), 1, 4)
        }, 0.25, 'outCubic')
      end
    })

    self.graph = createUniverse()
  end,

  update = function(self, dt)
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(180, 100)
    love.graphics.scale(2)

    renderGraph(self.graph, state.distScale)

    love.graphics.pop()
  end
})