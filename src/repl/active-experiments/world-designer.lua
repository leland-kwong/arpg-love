local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Collision = require 'repl.libs.collision'
local uid = dynamicRequire 'utils.uid'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'

local defaultValue = {
  connections = function()
    return {}
  end
}
local nodeMt = {
  position = Vec2(),
  __index = function(self, k)
    local val = rawget(self, k)

    if (val == nil) then
      local getDefaultValue = defaultValue[k]
      if getDefaultValue then
        val = getDefaultValue()
        rawset(self, k, val)
      end
    end

    return val
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
  get = function(self, id)
    return self.nodeList[id]
  end,
  delete = function(self, id)
    self.nodeList[id] = nil
    return self
  end,
  connect = function(self, node1, node2)
    local nodeRef1 = self:get(node1)
    local nodeRef2 = self:get(node2)
    nodeRef1.connections[node2] = true
    nodeRef2.connections[node1] = true
    return self
  end,
  traverse = function(self, node, callback, visited)
    visited = visited or {}
    local ref = self:get(node)
    for nodeId in pairs(ref.connections) do
      if (not visited[nodeId]) then
        visited[nodeId] = true
        local ref = self:get(nodeId)
        callback(nodeId)
        self:traverse(nodeId, callback, visited)
      end
    end
  end
}

local renderGraph = function(node)
  love.graphics.setColor(0,1,1)

  local connectionsToDraw = {}
  local connectionsAdded = {}
  Node:traverse(node, function(id)
    local ref = Node:get(id)
    love.graphics.circle('fill', ref.position.x, ref.position.y, 5)
    for targetId in pairs(ref.connections) do
      local pathString, pathStringReverse = id..targetId, targetId..id
      local isDuplicatePath = connectionsAdded[pathString] or connectionsAdded[pathStringReverse]
      if (not isDuplicatePath) then
        connectionsAdded[pathString] = true
        connectionsAdded[pathStringReverse] = true
        table.insert(connectionsToDraw, {id, targetId})
      end
    end
  end)

  love.graphics.setLineStyle('rough')
  for i=1, #connectionsToDraw do
    local path = connectionsToDraw[i]
    local id, targetId = path[1], path[2]
    local p1, p2 = Node:get(id).position, Node:get(targetId).position
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
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

    local level1 = Node:create({
      position = Vec2()
    })

    local level2 = Node:create({
      position = Vec2(
        Node:get(level1).position.x + 30,
        Node:get(level1).position.y
      )
    })
    Node:connect(level2, level1)

    local level3 = Node:create({
      position = Vec2(
        Node:get(level2).position.x + 60,
        Node:get(level2).position.y + 30
      )
    })
    Node:connect(level3, level2)

    local level4 = Node:create({
      position = Vec2(
        Node:get(level3).position.x + 30,
        Node:get(level3).position.y
      )
    })
    Node:connect(level4, level3)

    local level5 = Node:create({
      position = Vec2(
        Node:get(level4).position.x + 15,
        Node:get(level4).position.y + 25
      )
    })
    Node:connect(level5, level4)

    local level6 = Node:create({
      position = Vec2(
        Node:get(level4).position.x - 15,
        Node:get(level4).position.y + 25
      )
    })
    Node:connect(level6, level4)

    local avgPos = (Node:get(level2).position + Node:get(level3).position) / 2
    local secretLevel1 = Node:create({
      position = Vec2(
        avgPos.x,
        avgPos.y + 20
      )
    })
    Node:connect(secretLevel1, level2)
    Node:connect(secretLevel1, level3)

    self.renderGraph = function()
      renderGraph(level1)
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