local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local bump = require 'modules.bump'
local F = require 'utils.functional'
local nodeValueOptions = require 'scene.skill-tree-editor.node-data-options'
local inputState = require 'main.inputs'.state

--[[
  Instructions:

  click - place a node
  click node - selects node. If a node is already selected, creates a connection between both nodes
  drag node - moves node
  'delete' key - deletes selected node or connection
  's' key - executes serialization function
]]

local mouseCollisionWorld = bump.newWorld(32)
local mouseCollisionObject = {}
local mouseCollisionSize = 24
local cellSize = 20
mouseCollisionWorld:add(mouseCollisionObject, 0, 0, mouseCollisionSize, mouseCollisionSize)

local sourceDirectory = love.filesystem.getSourceBaseDirectory()
local pathToSave = sourceDirectory..'/src/scene/skill-tree-editor/serialized.lua'

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font
})

local function sortKeys(val)
  if type(val) ~= 'table' then
    return val
  end

  local newTable = {}
  local keys = {}
  for k in pairs(val) do
    table.insert(keys, k)
  end
  table.sort(keys)

  for i=1, #keys do
    local key = keys[i]
    newTable[key] = sortKeys(val[key])
  end

  return newTable
end

local TreeEditor = {
  loadState = function()
    local io = require 'io'
    local savedState = nil
    for line in io.lines(pathToSave) do
      savedState = (savedState or '')..line
    end

    -- IMPORTANT: In lua, key insertion order affects the order of serialization. So we should sort the keys to make sure it is deterministic.
    return sortKeys(
      savedState and loadstring(savedState)() or {}
    )
  end,
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

    --[[
      Love's `love.filesystem.write` doesn't support writing to files in the source directory,
      therefore we must use the `io` module.
    ]]
    local io = require 'io'
    local f = assert(io.open(pathToSave, 'w'))
    local success, message = f:write(
      ser(serializedTree)
    )
    if success then
      f:close()
      msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
        title = '[SKILL TREE] state saved',
      })
    else
      error(message)
    end
  end
}

local function snapToGrid(x, y)
  local Position = require 'utils.position'
  local gridX, gridY = Position.pixelsToGridUnits(x, y, cellSize)
  return Position.gridToPixels(gridX, gridY, cellSize)
end

local initialDx, initialDy = snapToGrid(1920/2, 1080/2)
local state = {
  hoveredNode = nil,
  selectedNode = nil,
  movingNode = nil,
  hoveredConnection = nil,
  selectedConnection = nil,
  translate = {
    startX = 0,
    startY = 0,
    dx = 0,
    dy = 0,
    dxTotal = initialDx,
    dyTotal = initialDy
  },
  mx = 0,
  my = 0
}

local function getMode()
  local InputContext = require 'modules.input-context'
  if 'gui' == InputContext.get() then
    return
  end

  if (inputState.keyboard.keysPressed.space) then
    return 'TREE_PANNING'
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

local function getTranslate()
  return state.translate.dxTotal + state.translate.dx,
    state.translate.dyTotal + state.translate.dy
end

local function clearSelections()
  state.selectedNode = nil
  state.selectedConnection = nil
end

-- creates a new node and adds it to the node tree
local function placeNode(root, nodeId, x, y, nodeSize, connections, nodeValue)
  local node = Gui.create({
    id = nodeId,
    inputContext = 'treeNode',
    x = x,
    y = y,
    width = nodeSize,
    height = nodeSize,
    scale = 1,

    connections = connections or {},
    nodeValue = nodeValue, -- stores the value by the option's key

    getMousePosition = function(self)
      local tx, ty = getTranslate()
      return love.mouse.getX() - tx,
        love.mouse.getY() - ty
    end,

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

function TreeEditor.loadFromSerializedState(self)
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

function TreeEditor.init(self)
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
    local _, _, button = unpack(event)

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
      local nodeSize = 40
      local snapX, snapY = snapToGrid(state.mx - nodeSize/2, state.my - nodeSize/2)
      placeNode(root, nil, snapX, snapY, nodeSize)
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
      local x, y = snapToGrid(state.mx - guiNode.width/2, state.my - guiNode.height/2)
      guiNode.x = x
      guiNode.y = y
      clearSelections()
    end

    if 'TREE_PANNING' == getMode() then
      local tx = state.translate
      tx.startX = event.startX
      tx.startY = event.startY
      local snapX, snapY = snapToGrid(event.dx, event.dy)
      tx.dx = snapX
      tx.dy = snapY
    end
  end)

  msgBus.on(msgBus.MOUSE_DRAG_END, function(event)
    state.movingNode = nil

    local tx = state.translate
    tx.dxTotal = tx.dxTotal + tx.dx
    tx.dyTotal = tx.dyTotal + tx.dy
    tx.startX = 0
    tx.startY = 0
    tx.dx = 0
    tx.dy = 0
  end)

  msgBus.on(msgBus.KEY_PRESSED, function(event)
    if (event.key == 'escape') then
      clearSelections()
    end

    local serializeTree = 's' == event.key and
      (inputState.keyboard.keysPressed.lctrl or inputState.keyboard.keysPressed.rctrl)
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

function TreeEditor.handleConnectionInteractions(self)
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

function TreeEditor.update(self, dt)
  local tx, ty = getTranslate()
  local mOffset = mouseCollisionSize
  state.mx, state.my = love.mouse.getX() - tx, love.mouse.getY() - ty
  mouseCollisionWorld:update(mouseCollisionObject, state.mx - mOffset, state.my - mOffset)

  self:handleConnectionInteractions()
  self.mode = getMode()
end

function TreeEditor.drawTreeCenter(self)
  local tx, ty = getTranslate()
  love.graphics.setColor(1,1,1)
  love.graphics.circle('fill', tx, ty, 10)
end

function TreeEditor.draw(self)
  local tx, ty = getTranslate()
  love.graphics.push()
  love.graphics.origin()

  self:drawTreeCenter()
  if 'NODE_CREATE' == self.mode then
    love.graphics.setColor(1,1,1,0.5)
    local x, y = snapToGrid(
      love.mouse.getX() - cellSize/2,
      love.mouse.getY() - cellSize/2
    )
    love.graphics.rectangle('line', x, y, cellSize, cellSize)
  end

  local function drawConnection(node, connectionNode)
    love.graphics.line(
      node.x + node.width/2 + tx,
      node.y + node.width/2 + ty,
      connectionNode.x + connectionNode.width/2 + tx,
      connectionNode.y + connectionNode.width/2 + ty
    )
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
        drawConnection(node, connectionNode)
      end

      local isHovered = state.hoveredConnection and state.hoveredConnection[nodeId] and state.hoveredConnection[connectionNodeId]
      local color = isHovered and Color.LIME or Color.WHITE
      love.graphics.setLineWidth(4)
      love.graphics.setColor(color)
      drawConnection(node, connectionNode)
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
    local x, y, radius = node.x + node.width/2 + tx, node.y + node.width/2 + ty, node.width/2
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

return Component.createFactory(TreeEditor)