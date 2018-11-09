local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local BeamStrike = require 'components.abilities.beam-strike'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local bump = require 'modules.bump'
local F = require 'utils.functional'
local NodeDataOptions = require 'scene.skill-tree-editor.node-data-options'
local inputState = require 'main.inputs'.state

local mouseCollisionWorld = bump.newWorld(32)
local mouseCollisionObject = {}
local mouseCollisionSize = 24
local cellSize = 40
mouseCollisionWorld:add(mouseCollisionObject, 0, 0, mouseCollisionSize, mouseCollisionSize)

--[[
  Instructions:

  click - place a node
  click node - selects node. If a node is already selected, creates a connection between both nodes
  drag node - moves node
  'delete' button - deletes selected node or connection
]]

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font
})

local PassiveTree = {
  debug = {
    connectionCount = true,
  },
  data = {}
}

local hoveredNode = nil
local selectedNode = nil
local hoveredConnection = nil
local selectedConnection = nil
local mx, my = 0,0

local function getMode()
  local InputContext = require 'modules.input-context'
  if 'gui' == InputContext.get() then
    return
  end

  if selectedNode and inputState.mouse.drag.isDragging then
    return 'NODE_MOVE'
  end

  if selectedNode and hoveredNode and (hoveredNode ~= selectedNode) then
    local hasConnection = Component.get(selectedNode).connections[hoveredNode]
    if (not hasConnection) then
      return 'CONNECTION_CREATE'
    end
  end

  if (not hoveredNode) and (not hoveredConnection) then
    if (selectedNode or selectedConnection) then
      return 'CLEAR_SELECTIONS'
    end
    return 'NODE_CREATE'
  end

  if hoveredNode then
    return 'NODE_SELECTION'
  end

  if hoveredConnection then
    return 'CONNECTION_SELECTION'
  end
end

local function clearSelections()
  selectedNode = nil
  selectedConnection = nil
end

local function snapToGrid(x, y)
  local Position = require 'utils.position'
  local gridX, gridY = Position.pixelsToGridUnits(x, y, cellSize)
  return Position.gridToPixels(gridX, gridY, cellSize)
end

local function placeNode(root, x, y, nodeSize)
  local snapX, snapY = snapToGrid(x - nodeSize/2, y - nodeSize/2)
  local node = Gui.create({
    inputContext = 'treeNode',
    x = snapX,
    y = snapY,
    width = nodeSize,
    height = nodeSize,
    scale = 1,

    connections = {},
    nodeData = {},

    onPointerMove = function(self)
      hoveredNode = self:getId()
    end,
    onPointerLeave = function(self)
      hoveredNode = nil
    end,
    onUpdate = function(self)
      if (not root.nodes[self:getId()]) then
        self:delete(true)
        hoveredNode = nil
        selectedNode = nil
      end
    end
  })

  return node:getId()
end

local function deleteConnection(connectionId)
  local connectionIds = F.keys(selectedConnection)
  local id1, id2 = unpack(connectionIds)
  Component.get(id1).connections[id2] = nil
  Component.get(id2).connections[id1] = nil
  clearSelections()
end

function PassiveTree.init(self)
  NodeDataOptions.create({
    id = 'nodeDataMenu',
    x = 0,
    y = 0,
    options = self.nodeDataOptions,

    -- set the node's data
    onSelect = function(name, value)
      local guiNode = Component.get(selectedNode)
      guiNode.nodeData = value
    end
  })

  local root = self
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  Component.get('mainMenu'):delete(true)

  love.mouse.setCursor()

  Component.addToGroup(self, 'gui')
  self.nodes = {}

  msgBus.on(msgBus.MOUSE_CLICKED, function(event)
    local mode = getMode()
    local x, y, button = unpack(event)

    if ('CLEAR_SELECTIONS' == mode) then
      return clearSelections()
    end

    if ('CONNECTION_CREATE' == mode) then
      local selection = selectedNode
      clearSelections()

      -- make connection between nodes
      local shouldDrawConnection = not not selection
      if shouldDrawConnection then
        local selectedGuiNode = Component.get(selection)
        local hoveredGuiNode = Component.get(hoveredNode)

        local lineData = {} -- if more points are added, we define a bezier curve
        hoveredGuiNode.connections[selection] = lineData
        selectedGuiNode.connections[hoveredNode] = lineData
        return
      end
    end

    if ('NODE_CREATE' == mode) and (button == 1) then
      self.nodes[placeNode(root, x, y, 40)] = true
    end

    if ('NODE_SELECTION' == mode) and (button == 1) then
      local alreadySelected = selectedNode == hoveredNode
      if alreadySelected then
        selectedNode = nil
      else
        selectedNode = hoveredNode
      end
    end

    if ('CONNECTION_SELECTION' == mode) and (button == 1) then
      clearSelections()
      selectedConnection = hoveredConnection
    end
  end)

  msgBus.on(msgBus.MOUSE_DRAG, function(event)
    if 'NODE_MOVE' == getMode() then
      local guiNode = Component.get(selectedNode)
      local x, y = snapToGrid(event.x - guiNode.width/2, event.y - guiNode.height/2)
      guiNode.x = x
      guiNode.y = y
    end
  end)

  msgBus.on(msgBus.KEY_PRESSED, function(event)
    if (event.key == 'escape') then
      clearSelections()
    end

    if 'delete' == event.key then
      if selectedConnection then
        deleteConnection(selectedConnection)
      end

      if selectedNode then
        -- remove connections
        local guiNode = Component.get(selectedNode)
        for toNodeId in pairs(guiNode.connections) do
          local toGuiNode = Component.get(toNodeId)
          toGuiNode.connections[selectedNode] = nil
        end

        -- remove node from list
        self.nodes[selectedNode] = nil
      end
    end
  end)
end

function PassiveTree.handleConnectionInteractions(self)
  -- handle connection collisions
  hoveredConnection = nil
  if (not hoveredNode) then
    for nodeId in pairs(self.nodes) do
      local node = Component.get(nodeId)

      for connectionNodeId in pairs(node.connections or {}) do
        local connectionNode = Component.get(connectionNodeId)
        local _, len = mouseCollisionWorld:querySegment(node.x, node.y, connectionNode.x, connectionNode.y)
        if len > 0 then
          hoveredConnection = {
            [nodeId] = true,
            [connectionNodeId] = true
          }
        end
      end
    end
  end
end

function PassiveTree.update(self, dt)
  local mOffset = mouseCollisionSize
  mx, my = love.mouse.getX(), love.mouse.getY()
  mouseCollisionWorld:update(mouseCollisionObject, mx - mOffset, my - mOffset)

  self:handleConnectionInteractions()
  self.mode = getMode()
end

function PassiveTree.draw(self)
  love.graphics.push()
  love.graphics.origin()

  if 'NODE_CREATE' == self.mode then
    love.graphics.setColor(1,1,1,0.5)
    local x, y = snapToGrid(
      love.mouse.getX() - cellSize/2,
      love.mouse.getY() - cellSize/2
    )
    love.graphics.rectangle('line', x, y, cellSize, cellSize)
  end

  -- draw connections
  for nodeId in pairs(self.nodes) do
    local node = Component.get(nodeId)

    for connectionNodeId in pairs(node.connections or {}) do
      local oLineWidth = love.graphics.getLineWidth()
      local connectionNode = Component.get(connectionNodeId)

      local isSelectedConnection = selectedConnection and
        (selectedConnection[connectionNodeId] and selectedConnection[nodeId])
      if isSelectedConnection then
        love.graphics.setLineWidth(8)
        love.graphics.setColor(1,0.2,1)
        love.graphics.line(
          node.x + node.width/2,
          node.y + node.width/2,
          connectionNode.x + connectionNode.width/2,
          connectionNode.y + connectionNode.width/2
        )
      end

      local isHovered = hoveredConnection and hoveredConnection[nodeId] and hoveredConnection[connectionNodeId]
      local color = isHovered and Color.LIME or Color.WHITE
      love.graphics.setLineWidth(4)
      love.graphics.setColor(color)
      love.graphics.line(
        node.x + node.width/2,
        node.y + node.width/2,
        connectionNode.x + connectionNode.width/2,
        connectionNode.y + connectionNode.width/2
      )
      love.graphics.setLineWidth(oLineWidth)
    end
  end

  -- draw nodes
  for nodeId in pairs(self.nodes) do
    local node = Component.get(nodeId)
    if node.hovered then
      love.graphics.setColor(0,1,0)
    else
      love.graphics.setColor(1,0.5,0)
    end
    local x, y, radius = node.x + node.width/2, node.y + node.width/2, node.width/2
    love.graphics.circle('fill', x, y, radius)

    if selectedNode == nodeId then
      local oLineWidth = love.graphics.getLineWidth()
      love.graphics.setLineWidth(4)
      love.graphics.setColor(1,1,1)
      love.graphics.circle('line', x, y, radius)
      love.graphics.setLineWidth(oLineWidth)
    end

    local nodeData = node.nodeData
    if nodeData.value then
      love.graphics.setColor(1,1,1)
      debugTextLayer:add(
        nodeData.value,
        Color.WHITE,
        x/2,
        y/2 -10
      )
    end

    if self.debug.connectionCount then
      debugTextLayer:add(
        #F.keys(node.connections),
        Color.WHITE,
        x / 2, y / 2
      )
    end
  end

  love.graphics.pop()
end

local Factory = Component.createFactory(PassiveTree)

local nodeDataOptions = {
  [1] = {
    name = 'attack speed',
    value = 1
  },
  [2] = {
    name = 'bonus damage',
    value = 0.2
  }
}

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local msgBusMainMenu = require 'components.msg-bus-main-menu'
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Factory,
      props = {
        nodeDataOptions = nodeDataOptions
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})