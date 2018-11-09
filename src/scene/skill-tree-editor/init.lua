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
local nodeValueOptions = require 'scene.skill-tree-editor.node-data-options'
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
  'delete' key - deletes selected node or connection
  's' key - executes serialization function
]]

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font
})

local PassiveTree = {
  debug = {
    connectionCount = true,
  },
  nodes = {},
  nodeValueOptions = {},
  serialize = function(self)
    local ser = require 'utils.ser'
    local serializedTree = {}
    for nodeId in pairs(self.nodes) do
      local node = Component.get(nodeId)
      serializedTree[nodeId] = node:serialize()
    end
    print(
      Inspect(serializedTree)
    )
  end
}

local state = {
  hoveredNode = nil,
  selectedNode = nil,
  movingNode = nil,
  hoveredConnection = nil,
  selectedConnection = nil,
  mx = 0,
  my = 0
}

local function getMode()
  local InputContext = require 'modules.input-context'
  if 'gui' == InputContext.get() then
    return
  end

  if (state.hoveredNode or state.movingNode) and inputState.mouse.drag.isDragging then
    return 'NODE_MOVE'
  end

  if state.selectedNode and state.hoveredNode and (state.hoveredNode ~= state.selectedNode) then
    local hasConnection = Component.get(state.selectedNode).connections[state.hoveredNode]
    if (not hasConnection) then
      return 'CONNECTION_CREATE'
    end
  end

  if (not state.hoveredNode) and (not state.hoveredConnection) then
    if (state.selectedNode or state.selectedConnection) then
      return 'CLEAR_SELECTIONS'
    end
    return 'NODE_CREATE'
  end

  if state.hoveredNode then
    return 'NODE_SELECTION'
  end

  if state.hoveredConnection then
    return 'CONNECTION_SELECTION'
  end
end

local function clearSelections()
  state.selectedNode = nil
  state.selectedConnection = nil
end

local function snapToGrid(x, y)
  local Position = require 'utils.position'
  local gridX, gridY = Position.pixelsToGridUnits(x, y, cellSize)
  return Position.gridToPixels(gridX, gridY, cellSize)
end

-- creates a new node and adds it to the node tree
local function placeNode(root, nodeId, x, y, nodeSize, connections, nodeValue)
  local snapX, snapY = snapToGrid(x - nodeSize/2, y - nodeSize/2)
  local node = Gui.create({
    id = nodeId,
    inputContext = 'treeNode',
    x = snapX,
    y = snapY,
    width = nodeSize,
    height = nodeSize,
    scale = 1,

    connections = connections or {},
    nodeValue = nodeValue, -- stores the value by the option's key

    serialize = function(self)
      return {
        x = self.x,
        y = self.y,
        size = nodeSize,
        connections = self.connections,
        nodeValue = self.nodeValue
      }
    end,

    onPointerMove = function(self)
      state.hoveredNode = self:getId()
    end,
    onPointerLeave = function(self)
      state.hoveredNode = nil
    end,
    onUpdate = function(self)
      if (not root.nodes[self:getId()]) then
        self:delete(true)
        state.hoveredNode = nil
        state.selectedNode = nil
      end
    end
  })

  local nodeId = node:getId()
  root.nodes[nodeId] = true
  return nodeId
end

local function deleteConnection(connectionId)
  local connectionIds = F.keys(state.selectedConnection)
  local id1, id2 = unpack(connectionIds)
  Component.get(id1).connections[id2] = nil
  Component.get(id2).connections[id1] = nil
  clearSelections()
end

function PassiveTree.loadFromSerializedState(self)
  for id,props in pairs(self.nodes) do
    placeNode(
      self,
      id,
      props.x,
      props.y,
      props.size,
      props.connections,
      props.nodeValue
    )
  end
end

function PassiveTree.init(self)
  local function setnodeValue(name, optionKey)
    local guiNode = Component.get(state.selectedNode)
    guiNode.nodeValue = optionKey
  end
  nodeValueOptions.create({
    id = 'nodeValueMenu',
    x = 0,
    y = 0,
    options = self.nodeValueOptions,

    -- set the node's data
    onSelect = setnodeValue
  })

  self:loadFromSerializedState()

  local root = self
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  Component.get('mainMenu'):delete(true)

  love.mouse.setCursor()

  Component.addToGroup(self, 'gui')

  msgBus.on(msgBus.MOUSE_CLICKED, function(event)
    local mode = getMode()
    local x, y, button = unpack(event)

    if ('CLEAR_SELECTIONS' == mode) then
      return clearSelections()
    end

    if ('CONNECTION_CREATE' == mode) then
      local selection = state.selectedNode
      clearSelections()

      -- make connection between nodes
      local shouldDrawConnection = not not selection
      if shouldDrawConnection then
        local selectedGuiNode = Component.get(selection)
        local hoveredGuiNode = Component.get(state.hoveredNode)

        local lineData = {} -- if more points are added, we define a bezier curve
        hoveredGuiNode.connections[selection] = lineData
        selectedGuiNode.connections[state.hoveredNode] = lineData
        return
      end
    end

    if ('NODE_CREATE' == mode) and (button == 1) then
      placeNode(root, nil, x, y, 40)
    end

    if ('NODE_SELECTION' == mode) and (button == 1) then
      local alreadySelected = state.selectedNode == state.hoveredNode
      if alreadySelected then
        state.selectedNode = nil
      else
        state.selectedNode = state.hoveredNode
      end
    end

    if ('CONNECTION_SELECTION' == mode) and (button == 1) then
      clearSelections()
      state.selectedConnection = state.hoveredConnection
    end
  end)

  msgBus.on(msgBus.MOUSE_DRAG, function(event)
    if 'NODE_MOVE' == getMode() then
      state.movingNode = state.movingNode or state.hoveredNode
      local guiNode = Component.get(state.movingNode)
      local x, y = snapToGrid(event.x - guiNode.width/2, event.y - guiNode.height/2)
      guiNode.x = x
      guiNode.y = y
      clearSelections()
    end
  end)

  msgBus.on(msgBus.MOUSE_DRAG_END, function(event)
    state.movingNode = nil
  end)

  msgBus.on(msgBus.KEY_PRESSED, function(event)
    if (event.key == 'escape') then
      clearSelections()
    end

    local serializeTree = 's' == event.key
    if serializeTree then
      self:serialize()
    end

    if 'delete' == event.key then
      if state.selectedConnection then
        deleteConnection(state.selectedConnection)
      end

      if state.selectedNode then
        -- remove connections
        local guiNode = Component.get(state.selectedNode)
        for toNodeId in pairs(guiNode.connections) do
          local toGuiNode = Component.get(toNodeId)
          toGuiNode.connections[state.selectedNode] = nil
        end

        -- remove node from list
        self.nodes[state.selectedNode] = nil
      end
    end
  end)
end

function PassiveTree.handleConnectionInteractions(self)
  -- handle connection collisions
  state.hoveredConnection = nil
  if (not state.hoveredNode) then
    for nodeId in pairs(self.nodes) do
      local node = Component.get(nodeId)

      for connectionNodeId in pairs(node.connections or {}) do
        local connectionNode = Component.get(connectionNodeId)
        local _, len = mouseCollisionWorld:querySegment(node.x, node.y, connectionNode.x, connectionNode.y)
        if len > 0 then
          state.hoveredConnection = {
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
  state.mx, state.my = love.mouse.getX(), love.mouse.getY()
  mouseCollisionWorld:update(mouseCollisionObject, state.mx - mOffset, state.my - mOffset)

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

      local isSelectedConnection = state.selectedConnection and
        (state.selectedConnection[connectionNodeId] and state.selectedConnection[nodeId])
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

      local isHovered = state.hoveredConnection and state.hoveredConnection[nodeId] and state.hoveredConnection[connectionNodeId]
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

    if state.selectedNode == nodeId then
      local oLineWidth = love.graphics.getLineWidth()
      love.graphics.setLineWidth(4)
      love.graphics.setColor(1,1,1)
      love.graphics.circle('line', x, y, radius)
      love.graphics.setLineWidth(oLineWidth)
    end

    local dataKey = node.nodeValue
    if dataKey then
      love.graphics.setColor(1,1,1)
      debugTextLayer:add(
        self.nodeValueOptions[dataKey].value,
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

local nodeValueOptions = {
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
        nodeValueOptions = nodeValueOptions,
        nodes = {
          a6a6495d_73 = {
            connections = {
              a6a6495d_75 = {},
              a73aac1c_74 = {}
            },
            nodeValue = 1,
            size = 40,
            x = 960,
            y = 400
          },
          a6a6495d_75 = {
            connections = {
              a6a6495d_73 = {}
            },
            size = 40,
            x = 1040,
            y = 440
          },
          a73aac1c_74 = {
            connections = {
              a6a6495d_73 = {}
            },
            nodeValue = 1,
            size = 40,
            x = 920,
            y = 320
          }
        }
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})