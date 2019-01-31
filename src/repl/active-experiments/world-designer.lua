local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Collision = require 'repl.libs.collision'
local uid = dynamicRequire 'utils.uid'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'
local Grid = require 'utils.grid'
local bump = require 'modules.bump'

bump.newWorld(32)

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
  default = {0,1,1},
  secret = {1,1,1,0}
}

local function renderNode(nodeId, distScale)
  love.graphics.setColor(0,1,1)
  local ref = Node:get(nodeId)
  local p = ref.position * distScale
  love.graphics.setColor(graphColors.default)
  love.graphics.circle('fill', p.x, p.y, 2)

  love.graphics.circle('line', p.x, p.y, 8)
end

local function renderLink(node1, node2, distScale)
  local ref1, ref2 = Node:get(node1),
    Node:get(node2)
  local p1, p2 = ref1.position * distScale, ref2.position * distScale
  love.graphics.setColor(
    (ref1.secret or ref2.secret) and
      graphColors.secret or
      graphColors.default
  )
  love.graphics.line(p1.x, p1.y, p2.x, p2.y)
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

    local model = Node:createModel()

    local level1 = Node:create({
      position = Vec2(),
      world = 'aureus'
    })

    local level2 = Node:create({
      position = Vec2(
        Node:get(level1).position.x + 30,
        Node:get(level1).position.y
      ),
      world = 'aureus'
    })
    model:addLink(level2, level1)

    local level3 = Node:create({
      position = Vec2(
        Node:get(level2).position.x + 60,
        Node:get(level2).position.y + 30
      )
    })
    model:addLink(level3, level2)

    local level4 = Node:create({
      position = Vec2(
        Node:get(level3).position.x + 30,
        Node:get(level3).position.y
      )
    })
    model:addLink(level4, level3)

    local level5 = Node:create({
      position = Vec2(
        Node:get(level4).position.x + 15,
        Node:get(level4).position.y + 25
      )
    })
    model:addLink(level5, level4)

    local level6 = Node:create({
      position = Vec2(
        Node:get(level4).position.x - 15,
        Node:get(level4).position.y + 25
      )
    })
    model:addLink(level6, level4)

    local avgPos = (Node:get(level2).position + Node:get(level3).position) / 2
    local secretLevel1 = Node:create({
      position = Vec2(
        avgPos.x - 15,
        avgPos.y + 40
      ),
      secret = true
    })
    model:addLink(secretLevel1, level2)
    model:addLink(secretLevel1, level3)

    local renderCanvas = love.graphics.newCanvas(4096, 4096)
    local distScale = 2 -- the amount to scale the distance between the nodes
    self.renderGraph = function()
      local nodesToRender = {}
      love.graphics.push()
      love.graphics.origin()
      local oBlendMode = love.graphics.getBlendMode()
      love.graphics.setBlendMode('alpha', 'premultiplied')
      love.graphics.setCanvas(renderCanvas)
      love.graphics.clear()
      love.graphics.setLineStyle('rough')

      model:forEach(function(_, node1, node2)
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

      love.graphics.stencil(function()
        love.graphics.setColor(1,1,1)
        for nodeId in pairs(nodesToRender) do
          local ref = Node:get(nodeId)
          local p = ref.position * distScale
          love.graphics.circle('fill', p.x, p.y, 12)
        end
      end, 'replace', 1)

      love.graphics.setStencilTest('notequal', 1)
      love.graphics.draw(renderCanvas)
      love.graphics.setStencilTest()

      love.graphics.setLineWidth(1)
      for nodeId in pairs(nodesToRender) do
        renderNode(nodeId, distScale)
      end
    end
  end,

  update = function(self, dt)
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(180, 100)
    love.graphics.scale(2)

    self.renderGraph()

    love.graphics.pop()
  end
})