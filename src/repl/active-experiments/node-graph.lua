local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Gui = require 'components.gui.gui'
local uid = dynamicRequire 'utils.uid'
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
  nodeList = {},
  -- returns an id for the node
  create = function(self, props)
    local node = setmetatable(props, nodeMt)
    local id = node.id or uid()
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
  local c = graphColors.region[ref.region] or graphColors.region.default
  love.graphics.setColor(c)
  love.graphics.circle('fill', p.x, p.y, 3)

  love.graphics.setColor(Color.multiplyAlpha(c, 0.3))
  love.graphics.circle('line', p.x, p.y, 9)
end

local labelOffsets = {
  top = function(textW, textH)
    return Vec2(-textW/2, -30)
  end
}
local function renderNodeLabel(nodeId, distScale, labelFont)
  love.graphics.setColor(1,1,1)
  local ref = Node:get(nodeId)
  local label = ref.level
  if label then
    local humanizedLabel = string.gsub(label, '_', ' ')
    local textW, textH = getTextSize(humanizedLabel, labelFont)
    local p = (ref.position * distScale) + labelOffsets[ref.labelPosition](textW, textH)
    love.graphics.print(humanizedLabel, p.x, p.y)
  end
end

local function renderRegionLabel(position, distScale, label, labelFont)
  love.graphics.setColor(1,1,1)
  local p = position * distScale
  love.graphics.print(label, p.x, p.y)
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
    region = 'saria'
  })
  model:addLink(level3, level2)

  local level4 = Node:create({
    position = Vec2(
      Node:get(level3).position.x + 30,
      Node:get(level3).position.y
    ),
    region = 'saria'
  })
  model:addLink(level4, level3)

  local level5 = Node:create({
    position = Vec2(
      Node:get(level4).position.x + 15,
      Node:get(level4).position.y + 25
    ),
    region = 'saria'
  })
  model:addLink(level5, level4)

  local level6 = Node:create({
    position = Vec2(
      Node:get(level4).position.x - 15,
      Node:get(level4).position.y + 25
    ),
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
    region = 'secret'
  })
  model:addLink(secretLevel1, level2)

  local avgPos = (Node:get(level2).position + Node:get(level4).position) / 2
  local secretLevel2 = Node:create({
    position = Vec2(
      avgPos.x + 6,
      avgPos.y - 15
    ),
    secret = true,
    region = 'secret'
  })
  model:addLink(secretLevel2, level4)

  return model
end

local renderCanvas = love.graphics.newCanvas(4096, 4096)
local renderGraph = function(graph, distScale)
  local nodesToRender = {}
  love.graphics.push()
  love.graphics.origin()
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.setCanvas(renderCanvas)
  love.graphics.clear()
  love.graphics.setLineStyle('rough')

  graph:forEach(function(_, node1, node2)
    if (not nodesToRender[node1]) then
      nodesToRender[node1] = node1
    end
    if (not nodesToRender[node2]) then
      nodesToRender[node2] = node2
    end
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
        Component.animate(state, {
          distScale = clamp(state.distScale + dy, 1, 4)
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