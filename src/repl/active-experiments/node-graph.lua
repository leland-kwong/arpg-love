local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'
local Grid = require 'utils.grid'
local Color = require 'modules.color'
local Font = require 'components.font'
local getTextSize = require 'repl.libs.get-text-size'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local GuiContext = dynamicRequire 'repl.libs.gui'
local camera = require 'components.camera'
local memoize = require 'utils.memoize-one'

local Gui = GuiContext()

local state = {
  distScale = 1,
  translate = Vec2(0, 20),
  unlockedNodes = {
    [1] = true,
    [2] = true,
    [7] = true
  },
  hoveredNode = nil,
  nodeStyles = {}
}

local getNodeHoveredScale = memoize(function (node)
  local subject = {scale = 1}
  Component.animate(subject, {
    scale = 1.4
  }, 0.25, 'outCubic')

  return function()
    return subject.scale
  end
end)

local actions = {
  pan = function(dx, dy)
    state.initialTranslate = state.initialTranslate or state.translate
    state.translate = state.initialTranslate + Vec2(dx, dy)
  end,
  panEnd = function()
    state.initialTranslate = nil
  end,
  zoom = function(dz)
    local clamp = require 'utils.math'.clamp
    local round = require 'utils.math'.round
    Component.animate(state, {
      distScale = clamp(round(state.distScale + dz), 1, 2)
    }, 0.25, 'outCubic')
  end,
  nodeHoverIn = function(node)
    Component.animate(state.nodeStyles[node], {
      scale = 1.3
    }, 0.15, 'outQuint')
  end,
  nodeHoverOut = function(node)
    Component.animate(state.nodeStyles[node], {
      scale = 1
    }, 0.15, 'outQuint')
  end,
  nodeSelect = function(node)
    print('select', node)
  end,
  newGraph = function(model)
    state.nodeStyles = {}
    model:forEach(function(link)
      local node1, node2 = unpack(link)
      state.nodeStyles[node1] = {
        scale = 1
      }
      state.nodeStyles[node2] = {
        scale = 1
      }
    end)
  end
}

local nodeMt = {
  position = Vec2()
}
local modelMt = {
  addLink = function(self, node1, node2)
    self.id = self.id + 1
    local link = {node1, node2}
    self.links[self.id] = link
    return self.id
  end,

  removeLink = function(self, linkId)
    self.links[linkId] = nil
    return self
  end,

  getLink = function(self, linkId)
    return self.links[linkId]
  end,

  hasNode = function(self, node)
    return self.nodes[node] ~= nil
  end,

  forEach = function(self, callback)
    for _,link in pairs(self.links) do
      callback(link)
    end
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
      id = 0,
      nodes = {},
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
  link = {1,1,1},
  linkLocked = {1,1,1,0.25}
}

local function renderNode(nodeId, distScale)
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

local function nodeGraphTest()
  local model = Node:createModel()
  local n1 = Node:create()
  local n2 = Node:create()
  model:addLink(n1, n2)

  assert(model:hasNode(n1) and model:hasNode(n2))

  local n3 = Node:create()
  model:addLink(n2, n3)
end

local createUniverse = function()
  local model = Node:createModel()

  local level1 = Node:create({
    position = Vec2(20, 30),
    region = 'aureus',
    level = 'a-1',
    labelPosition = 'top'
  })

  local level2 = Node:create({
    position = Vec2(
      Node:get(level1).position.x + 40,
      Node:get(level1).position.y
    ),
    region = 'aureus',
    level = 'a-2',
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
      avgPos.x + 5,
      avgPos.y - 32
    ),
    secret = true,
    region = ''
  })
  model:addLink(secretLevel2, level3)

  actions.newGraph(model)

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
  id = 'UniverseMap',
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

    -- full-screen event handler
    Gui({
      x = 0,
      y = 0,
      w = love.graphics.getWidth(),
      h = love.graphics.getHeight(),
      MOUSE_DRAG = function(self, ev)
        actions.pan(ev.dx, ev.dy)
      end,
      MOUSE_DRAG_END = function(self)
        actions.panEnd()
      end,
      MOUSE_WHEEL_MOVED = function(self, ev)
        local dy = ev[2]
        actions.zoom(dy)
      end
    })

    self.graph = createUniverse()

    local guiNodes = {}
    self.guiNodes = guiNodes
    local function createGraphNodeGuiElement(node)
      local nodeRef = Node:get(node)
      local p = nodeRef.position * state.distScale
      return Gui({
        x = p.x,
        y = p.y,
        size = 24,
        -- debug = true,
        MOUSE_ENTER = function(self)
          actions.nodeHoverIn(node)
        end,
        MOUSE_LEAVE = function(self)
          actions.nodeHoverOut(node)
        end,
        MOUSE_PRESSED = function(self)
          actions.nodeSelect(node)
        end,
        update = function(self)
          local size = self.size
          local p = (nodeRef.position * state.distScale - Vec2(size/2, size/2)) * camera.scale + state.translate
          self:setPosition(p.x, p.y)
          self:setSize(size * camera.scale)
        end,
        renderDebug = function(self)
          if not self.debug then
            return
          end
          local color = self.hovered and {1,1,0,0.1} or {1,1,1,0.1}
          love.graphics.setColor(color)
          love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
        end,
      })
    end
    self.updateGuiNodes = function(dt)
      for nodeId,guiNode in pairs(self.guiNodes) do
        guiNode:update(dt)
      end
    end

    self.renderGuiDebug = function()
      love.graphics.push()
      love.graphics.origin()
      for _,guiNode in pairs(self.guiNodes) do
        guiNode:renderDebug()
      end
      love.graphics.pop()
    end

    self.graph:forEach(function(link)
      local node1, node2 = link[1], link[2]
      if (not guiNodes[node1]) then
        guiNodes[node1] = createGraphNodeGuiElement(node1)
      end
      if (not guiNodes[node2]) then
        guiNodes[node2] = createGraphNodeGuiElement(node2)
      end
    end)
  end,

  update = function(self, dt)
    Gui:update(dt)
    self.updateGuiNodes(dt)
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(state.translate.x, state.translate.y)
    love.graphics.scale(camera.scale)

    renderGraph(self.graph, state.distScale)
    self.renderGuiDebug()

    love.graphics.pop()
  end,

  final = function(self)
    Gui:destroy()
  end
})