local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local config = require 'config.config'
local Color = require 'modules.color'
local bump = require 'modules.bump'
local F = require 'utils.functional'
local nodeValueOptions = require 'components.skill-tree-editor.node-data-options'
local inputState = require 'main.inputs'.state
local Object = require 'utils.object-utils'
local noop = require 'utils.noop'
local rebuildTableBySortingKeys = require 'components.skill-tree-editor.rebuild-table-by-sorting-keys'
local Sound = require 'components.sound'
local InputContext = require 'modules.input-context'


local sounds = {
  NODE_SELECT = 'gui/UI_Animate_Clean_Beeps_Appear_stereo.wav',
  NODE_UNSELECT = 'gui/UI_Animate_Clean_Beeps_Disappear_stereo.wav'
}

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
local mouseCollisionSize = 50
mouseCollisionWorld:add(mouseCollisionObject, 0, 0, mouseCollisionSize, mouseCollisionSize)

local TreeEditor = {
  debug = {
    -- connectionCount = true,
    -- selectionTraversal = true,
  },
  nodes = nil,
  nodeValueOptions = {},
  onChange = noop,
  onSerialize = noop,
  serialize = function(self)
    local ser = require 'utils.ser'
    local serializedTree = rebuildTableBySortingKeys(self.nodes)

    --[[
      Love's `love.filesystem.write` doesn't support writing to files in the source directory,
      therefore we must use the `io` module.
    ]]
    local serializedTreeAsString = ser(serializedTree)
    local isNewState = previousSerializedTreeAsString ~= serializedTreeAsString
    previousSerializedTreeAsString = serializedTreeAsString

    if isNewState then
      self:onSerialize(serializedTreeAsString, serializedTree)
    end
  end
}

local Enum = require 'utils.enum'
local baseCellSize = 25
local editorModes = Enum({
  'EDIT',

  -- these modes are for in-game views
  'PLAY',
  'PLAY_READ_ONLY',
  'PLAY_UNSELECT_ONLY'
})
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
    dxTotal = 0,
    dyTotal = 0
  },
  mx = 0,
  my = 0,
  scale = 2,
  editorMode = editorModes.EDIT,
}

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font,
  drawOrder = function()
    return 10
  end
})

local cellSize = baseCellSize * state.scale

local function snapToGrid(x, y)
  local Position = require 'utils.position'
  local gridX, gridY = Position.pixelsToGridUnits(x, y, cellSize)
  return Position.gridToPixels(gridX, gridY, cellSize)
end

function TreeEditor.getMode(self)
  if 'gui' == InputContext.get() then
    return
  end

  if editorModes.EDIT == self.editorMode then
    if (state.hoveredNode or state.movingNode) and inputState.mouse.drag.isDragging then
      return 'NODE_MOVE'
    end

    if state.selectedNode and state.hoveredNode and (state.hoveredNode ~= state.selectedNode) then
      local hasConnection = self.nodes[state.selectedNode].connections[state.hoveredNode]
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

    if state.hoveredConnection then
      return 'CONNECTION_SELECTION'
    end
  end

  if state.hoveredNode then
    return 'NODE_SELECTION'
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

local debugState = {
  checkedNodes = {},
  firstCheckedNode = nil,
}

local playMode = {
  --[[
    Conditions
    1. One of its neighbors must already be selected or a root node
  ]]
  isNodeSelectable = function(self, nodeToCheck, nodeList, nodeValueOptions)
    local nodeValue = nodeToCheck.nodeValue
    local nodeData = nodeValueOptions[nodeValue]

    -- if any node has a selected connection, then it is selectable
    for id in pairs(nodeToCheck.connections) do
      if nodeList[id].selected then
        return true
      end
    end
    return false
  end,
  --[[
    Conditions
    1. All sibling nodes must be connected to at least a single branch
  ]]
  isNodeUnselectable = function(self, nodeToCheck, nodeList, nodeToCheckId)
    local F = require 'utils.functional'
    local numSelectedSiblingNodes = 0
    local numSiblings = #F.keys(nodeToCheck.connections)
    local numSiblingsWithConnectionsToAnotherSibling = 0

    local function getMatchCount(fromNodeId, connectionsToMatch, visitedList)
      visitedList = visitedList or {}
      debugState.checkedNodes = visitedList
      local connections = nodeList[fromNodeId].connections
      return F.reduce(F.keys(connections), function(totalMatchCount, nodeId)
        local isAlreadyMatched = (nodeId == nodeToCheckId) or visitedList[nodeId]
        if isAlreadyMatched then
          return totalMatchCount
        end

        local isMatch = connectionsToMatch[nodeId] ~= nil
        local isSelectedNode = nodeList[nodeId].selected
        local matches = (isMatch and isSelectedNode) and 1 or 0
        visitedList[nodeId] = true
        local siblingMatches = isSelectedNode and getMatchCount(nodeId, connectionsToMatch, visitedList) or 0
        return totalMatchCount + (matches + siblingMatches)
      end, 0)
    end

    local siblings = F.keys(nodeToCheck.connections)
    local selectedSiblings = F.filter(siblings, function(siblingId)
      return nodeList[siblingId].selected
    end)
    local numSelectedSiblings = #selectedSiblings
    local nodeIdToWalk = selectedSiblings[1]
    debugState.firstCheckedNode = nodeIdToWalk
    local matchCount = getMatchCount(nodeIdToWalk, nodeToCheck.connections)
    local isOnlyChild = numSelectedSiblings == 1
    return isOnlyChild or numSelectedSiblings == matchCount
  end,
  isConnectionToSelectableNode = function(self, fromNode, toNode)
    if editorModes.PLAY == state.editorMode then
      return fromNode.selected or toNode.selected
    end

    if (editorModes.PLAY_READ_ONLY == state.editorMode) or
      (editorModes.PLAY_UNSELECT_ONLY == state.editorMode) then
      return fromNode.selected and toNode.selected
    end
  end
}

-- creates a new node and adds it to the node tree
local function placeNode(root, nodeId, gridX, gridY, connections, nodeValue, selected, size)
  size = size or 1

  local oScale = state.scale
  local node = Gui.create({
    id = nodeId,
    inputContext = 'treeNode',
    scale = 1,

    onClick = function(self, event)
      local mode = root:getMode()
      local _, _, button = unpack(event)
      local nodeId = self:getId()

      if ('CONNECTION_CREATE' == mode) then
        local selection = state.selectedNode
        clearSelections()

        -- make connection between nodes
        local shouldAddConnection = not not selection
        if shouldAddConnection then
          local selectedNodeData = root.nodes[selection]
          local hoveredNodeData = root.nodes[state.hoveredNode]

          local lineData = {} -- if more points are added, we define a bezier curve
          root:setNode(state.hoveredNode, {
            connections = Object.immutableApply(
              hoveredNodeData.connections, {
                [selection] = lineData
              }
            )
          })
          root:setNode(selection, {
            connections = Object.immutableApply(
              selectedNodeData.connections, {
                [state.hoveredNode] = lineData
              }
            )
          })
          return
        end
      end

      if ('NODE_SELECTION' == mode) and (button == 1) then
        local node = root.nodes[nodeId]

        if (editorModes.PLAY_UNSELECT_ONLY == state.editorMode) then
          if (node.selected) then
            Sound.playEffect(sounds.NODE_UNSELECT)
            root:setNode(nodeId, {
              selected = false
            })
          end
        elseif (editorModes.PLAY == state.editorMode) then
          local isNotSelectable = (
              (not node.selected)
              and (not playMode:isNodeSelectable(node, root.nodes, root.nodeValueOptions))
            ) or
            (
              node.selected
              and (not playMode:isNodeUnselectable(node, root.nodes, nodeId))
            )
          if (isNotSelectable) then
            msgBus.send(msgBus.PLAYER_ACTION_ERROR, 'previous node must be selected first')
            return
          end
          local isSelected = not node.selected
          if isSelected then
            Sound.playEffect(sounds.NODE_SELECT)
          else
            Sound.playEffect(sounds.NODE_UNSELECT)
          end
          root:setNode(nodeId, {
            selected = isSelected
          })
          return
        end

        local alreadySelected = state.selectedNode == nodeId
        if alreadySelected then
          state.selectedNode = nil
        else
          state.selectedNode = nodeId
        end
      end
    end,

    getMousePosition = function(self)
      local tx, ty = getTranslate()
      return love.mouse.getX() - tx,
        love.mouse.getY() - ty
    end,

    onPointerMove = function(self)
      -- in any non-edit mode, prevent selection if the node is read only
      if editorModes.EDIT ~= root.editorMode then
        local dataRef = root.nodes[self:getId()]
        local nodeData = root.nodeValueOptions[dataRef.nodeValue]
        local isReadOnly = (not nodeData) or nodeData.readOnly
        if isReadOnly then
          return
        end
      end

      state.hoveredNode = self:getId()
    end,
    onPointerLeave = function(self)
      state.hoveredNode = nil
    end,
    onUpdate = function(self)
      local dataRef = root.nodes[self:getId()]
      if (not dataRef) then
        self:delete(true)
        state.hoveredNode = nil
        state.selectedNode = nil
        return
      end
      local optionValue = root.nodeValueOptions[nodeValue]
      local AnimationFactory = require 'components.animation-factory'
      local animation = AnimationFactory:newStaticSprite(
        optionValue and optionValue.image or root.defaultNodeImage
      )
      local width, height = animation:getWidth(), animation:getHeight()
      self.width, self.height = width * state.scale, height * state.scale
      local ox, oy = (cellSize - self.width)/2,
        (cellSize - self.height)/2
      dataRef.size = cellSize
      self.x, self.y = dataRef.x * cellSize + ox, dataRef.y * cellSize + oy
    end
  }):setParent(root)

  local nodeId = node:getId()
  root:setNode(nodeId, {
    x = gridX,
    y = gridY,
    connections = connections or {},
    nodeValue = nodeValue, -- stores the value by the option's key
    selected = selected or false, -- whether the node has been "bought"
  })
  return nodeId
end

--[[
  immutably updates the entire node tree by shallow copying the tree
  and making a copy of the node to be changed
]]
function TreeEditor.setNode(self, nodeId, props)
  if state.editorMode == 'PLAY_READ_ONLY' then
    return
  end

  assert(type(nodeId) == 'string', 'nodeId should be a string')
  assert(props == nil or type(props) == 'table', 'props should be a table')

  local node = self.nodes[nodeId]
  local Object = require 'utils.object-utils'
  local previousState = self.nodes
  self.nodes = Object.clone(self.nodes)
  self.nodes[nodeId] = props and Object.immutableApply(node, props) or nil
  self:onChange(self.nodes, previousState)
end

function TreeEditor.deleteConnection(self, connectionId)
  local connectionIds = F.keys(state.selectedConnection)
  local id1, id2 = unpack(connectionIds)
  local node1, node2 = self.nodes[id1], self.nodes[id2]
  node1.connections[id2] = nil
  node2.connections[id1] = nil
  clearSelections()
end

function TreeEditor.loadFromSerializedState(self)
  local originalEditorMode = self.editorMode
  state.editorMode = 'PLAY'

  for id,props in pairs(rebuildTableBySortingKeys(self.nodes)) do
    placeNode(
      self,
      id,
      -- restore coordinates as pixel units
      props.x,
      props.y,
      props.connections,
      props.nodeValue,
      props.selected
    )
  end

  state.editorMode = originalEditorMode
end

function TreeEditor.handleInputs(self)
  local root = self

  local function handleZoom(ev)
    local dy = ev[2]

    local function changeScale(ds)
      local clamp = require 'utils.math'.clamp
      state.scale = clamp(state.scale + ds, 1, 5)
    end

    changeScale(dy)
  end

  local Gui = require 'components.gui.gui'
  Gui.create({
    id = 'skill-tree',
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight(),
    onClick = function(_, event)
      local mode = root:getMode()
      local button = select(3, unpack(event))
      if ('NODE_CREATE' == mode) and (button == 1) then
        local snapX, snapY = snapToGrid(state.mx - cellSize/2, state.my - cellSize/2)
        placeNode(root, nil, snapX/cellSize, snapY/cellSize, nil, nil, nil, cellSize)
      end

      if ('CLEAR_SELECTIONS' == mode) then
        return clearSelections()
      end

      if ('CONNECTION_SELECTION' == mode) and (button == 1) then
        clearSelections()
        state.selectedConnection = state.hoveredConnection
      end
    end
  }):setParent(self)

  self.listeners = {
    msgBus.on(msgBus.MOUSE_WHEEL_MOVED, function(ev)
      if InputContext.contains('skill-tree treeNode') then
        handleZoom(ev)
      end
    end),
    msgBus.on(msgBus.MOUSE_DRAG, function(event)
      if 'NODE_MOVE' == self:getMode() then
        state.movingNode = state.movingNode or state.hoveredNode
        local nodeData = self.nodes[state.movingNode]
        local x, y = snapToGrid(state.mx - cellSize/2, state.my - cellSize/2)
        self:setNode(state.movingNode, {
          x = x/cellSize,
          y = y/cellSize
        })
        clearSelections()
      else
        -- panning
        local tx = state.translate
        tx.startX = event.startX
        tx.startY = event.startY
        tx.dx = math.floor(event.dx)
        tx.dy = math.floor(event.dy)
      end
    end),

    msgBus.on(msgBus.MOUSE_DRAG_END, function(event)
      state.movingNode = nil

      -- update tree translation
      local tx = state.translate
      tx.dxTotal, tx.dyTotal = tx.dxTotal + tx.dx, tx.dyTotal + tx.dy
      if (editorModes.EDIT == state.editorMode) then
        tx.dxTotal, tx.dyTotal = snapToGrid(tx.dxTotal, tx.dyTotal)
      end
      tx.startX = 0
      tx.startY = 0
      tx.dx = 0
      tx.dy = 0
    end),

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
          root:deleteConnection(state.selectedConnection)
        end

        -- delete node
        if state.selectedNode then
          -- remove connections
          local nodeData = root.nodes[state.selectedNode]
          for toNodeId in pairs(nodeData.connections) do
            local toNodeData = root.nodes[toNodeId]
            toNodeData.connections[state.selectedNode] = nil
          end

          -- remove node from list
          self:setNode(state.selectedNode, nil)
          clearSelections()
        end
      end
    end)
  }
end

function TreeEditor.panTo(self, x, y)
  local shouldCenter = not x
  if shouldCenter then
    local halfCell = math.floor(cellSize/2)
    local offset = -halfCell -- offset the panning of the center to be centered to the grid
    x, y = love.graphics.getWidth() / 2 + offset, love.graphics.getHeight() / 2 + offset
  end
  state.translate.dxTotal, state.translate.dyTotal = x, y
end

function TreeEditor.init(self)
  self:handleInputs()
  self:panTo()

  -- load default state
  if (not self.nodes) then
    local defaultLayout = 'components.skill-tree-editor.layout'
    self.nodes = require(defaultLayout)
  end

  self:loadFromSerializedState()

  local tick = require 'utils.tick'
  local previousNodesList = self.nodes
  local function autoSerialize()
    local isDirty = previousNodesList ~= self.nodes
    if isDirty then
      self:serialize()
    end
    previousNodesList = self.nodes
  end
  self.autoSave = tick.recur(autoSerialize, 1/60)

  love.mouse.setCursor()

  Component.addToGroup(self, 'gui')
end

function TreeEditor.handleConnectionInteractions(self)
  -- handle connection collisions
  state.hoveredConnection = nil
  if (not state.hoveredNode) then
    for nodeId,node in pairs(self.nodes) do
      for connectionNodeId in pairs(node.connections or {}) do
        local connectionNode = self.nodes[connectionNodeId]
        local _, len = mouseCollisionWorld:querySegment(node.x * cellSize, node.y * cellSize, connectionNode.x * cellSize, connectionNode.y * cellSize)
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

function TreeEditor.showNodeValueOptionsMenu(self)
  if (not state.selectedNode) then
    if self.nodeValueOptionsMenu then
      self.nodeValueOptionsMenu:delete(true)
      self.nodeValueOptionsMenu = nil
    end
    return
  end

  if self.nodeValueOptionsMenu then
    return
  end

  local function setnodeValue(name, optionKey)
    self:setNode(state.selectedNode, {
      nodeValue = optionKey
    })
    clearSelections()
  end
  self.nodeValueOptionsMenu = self.nodeValueOptionsMenu or nodeValueOptions.create({
    id = 'nodeValueMenu',
    x = 0,
    y = 0,
    options = self.nodeValueOptions,

    -- set the node's data
    onSelect = setnodeValue
  })
end

local backgroundColorByEditorMode = {
  [editorModes.EDIT] = Color.DARK_GRAY,
  [editorModes.PLAY] = Color.DARK_GRAY_BLUE,
  [editorModes.PLAY_READ_ONLY] = Color.DARK_GRAY_BLUE,
  [editorModes.PLAY_UNSELECT_ONLY] = Color.DARK_GRAY_BLUE
}

function TreeEditor.update(self, dt)
  cellSize = baseCellSize * state.scale
  debugTextLayer.scale = state.scale

  if (InputContext.get() == 'any') then
    InputContext.set('SkillTreeBackground')
  end

  local cursorType = ((not state.hoveredNode) and (not state.selectedNode) and (not state.hoveredConnection))
    and 'move'
    or 'default'
  msgBus.send(msgBus.CURSOR_SET, {type = cursorType})

  local tx, ty = getTranslate()
  local mOffset = mouseCollisionSize
  state.mx, state.my = love.mouse.getX() - tx, love.mouse.getY() - ty
  mouseCollisionWorld:update(mouseCollisionObject, state.mx - mOffset, state.my - mOffset)

  if editorModes.EDIT == state.editorMode then
    self:showNodeValueOptionsMenu()
    self:handleConnectionInteractions()
  end
  self.mode = self:getMode()
  state.editorMode = self.editorMode or editorModes.EDIT

  if (editorModes.PLAY ~= state.editorMode) then
    self.clock = 0
    self.direction = 1
  else
    self.direction = self.direction or 1
    self.clock = (self.clock or 0) + (dt * self.direction) * 4
    if self.clock > math.pi/2 then
      self.direction = -1
    elseif self.clock <= 0 then
      self.direction = 1
    end
  end
end

function TreeEditor.drawTreeCenter(self)
  if editorModes.EDIT ~= state.editorMode then
    return
  end
  local tx, ty = getTranslate()
  love.graphics.setColor(1,1,1)
  love.graphics.circle('fill', tx, ty, 10)
end

local tooltipOptionsMt = {
  beforeRender = require('utils.noop'),
  position = function(tt)
    return 0, 0
  end,
  padding = 4,
  minWidth = 100,
  maxWidth = 100
}
tooltipOptionsMt.__index = tooltipOptionsMt
local function renderTooltip(blocks, font, options)
  options = setmetatable(options or {}, tooltipOptionsMt)
  local tt = {
    width = 0,
    height = 0,
    blocks = {}
  }
  local Grid = require 'utils.grid'
  local rowWidth = 0
  local rowHeight = 0
  local currentRow = nil
  local function setupTooltip(block, col, row)
    local isNewRow = row ~= currentRow
    if isNewRow then
      -- update tooltip dimensions
      tt.width = math.max(tt.width, rowWidth)
      tt.height = tt.height + rowHeight

      currentRow = row
      rowWidth = 0
      rowHeight = 0
    end

    table.insert(tt.blocks, {
      x = rowWidth,
      y = tt.height,
      content = block.content,
      align = block.align or 'left'
    })

    local tWidth, tHeight = GuiText.getTextSize(block.content, font, options.maxWidth)
    rowWidth = rowWidth + tWidth
    rowHeight = math.max(rowHeight, tHeight)
  end
  Grid.forEach(blocks, setupTooltip)
  -- update tooltip final dimensions
  local clamp = require 'utils.math'.clamp
  tt.width = clamp(math.max(tt.width, rowWidth), options.minWidth, options.maxWidth) + (options.padding * 2)
  tt.height = tt.height + rowHeight + (options.padding * 2)

  local x,y = options.position(tt)
  options.beforeRender(tt, x, y)
  love.graphics.setFont(font)
  local padding = {
    left = options.padding,
    center = 0,
    right = -options.padding
  }
  for _,block in ipairs(tt.blocks) do
    love.graphics.printf(
      block.content,
      math.floor(x + padding[block.align] + block.x),
      math.floor(y + options.padding + block.y),
      tt.width,
      block.align
    )
  end
end

function TreeEditor.drawTooltip(self)
  if (not state.hoveredNode) then
    return
  end

  local node = self.nodes[state.hoveredNode]
  local dataKey = node.nodeValue
  local optionValue = self.nodeValueOptions[dataKey]
  local String = require 'utils.string'
  local tooltipTitle = String.capitalize(optionValue and optionValue.name or '')
  local tooltipBody = optionValue and optionValue:description() or self.defaultNodeDescription
  local tooltipScale = config.scale
  local tx, ty = getTranslate()

  local font = require 'components.font'.primary.font
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(tooltipScale)
    local constants = require 'components.state.constants'
    renderTooltip(
      {
        {
          {
            content = {
              Color.WHITE, tooltipTitle,
              Color.WHITE, '\n\n'..tooltipBody,
            },
            align = 'left'
          }
        },
        {
          {
            content = {
              Color.PALE_YELLOW, '\n'..constants.glyphs.leftMouseBtn..' to '..(node.selected and 'unselect' or 'select')
            },
            align = 'right'
          }
        },
        {
          {
            content = {
              Color.MED_GRAY, '(bonuses are multiplied on top of items)'
            },
            align = 'right'
          }
        },
      },
      font,
      {
        minWidth = 0,
        maxWidth = 200,
        padding = 4,
        position = function(tt)
          return (node.x * cellSize + cellSize/2 + tx)/tooltipScale - tt.width/2,
          (node.y * cellSize + ty)/tooltipScale - tt.height
        end,
        beforeRender = function(tt, x, y)
          -- background
          love.graphics.setColor(0,0,0)
          love.graphics.rectangle('fill', x, y, tt.width, tt.height)
          -- border
          love.graphics.setColor(1,1,1)
          love.graphics.rectangle('line', x, y, tt.width, tt.height)
        end
      }
    )
  love.graphics.pop()
end

local function drawBackground()
  -- create background
  love.graphics.setColor(backgroundColorByEditorMode[state.editorMode])
  love.graphics.rectangle(
    'fill',
    0, 0, love.graphics.getWidth(), love.graphics.getHeight()
  )
end

local function drawHelpText()
  local font = require 'components.font'.primary.font
  local constants = require 'components.state.constants'
  love.graphics.setColor(1,1,1)
  love.graphics.setFont(font)
  local text = {
    Color.WHITE,
    constants.glyphs.leftMouseBtn,
    Color.WHITE,
    ' drag to move tree\n',

    Color.WHITE,
    constants.glyphs.middleMouseBtn,
    Color.WHITE,
    ' zoom tree'
  }
  love.graphics.printf(text, 10, 10, 200, 'left')
end

local mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]

function TreeEditor.draw(self)
  drawBackground(self)

  local _editorMode = state.editorMode
  local tx, ty = getTranslate()
  love.graphics.push()
  love.graphics.origin()

  self:drawTreeCenter()

  -- draw mouse preview position
  if 'NODE_CREATE' == self.mode then
    love.graphics.setColor(1,1,1,0.5)
    local x, y = snapToGrid(
      love.mouse.getX() - cellSize/2,
      love.mouse.getY() - cellSize/2
    )
    love.graphics.rectangle('line', x, y, cellSize, cellSize)
  end

  local function drawConnection(node, connectionNode)
    love.graphics.setLineStyle('rough')
    love.graphics.line(
      (node.x * cellSize) + cellSize/2 + tx,
      (node.y * cellSize) + cellSize/2 + ty,
      (connectionNode.x * cellSize) + connectionNode.size/2 + tx,
      (connectionNode.y * cellSize) + connectionNode.size/2 + ty
    )
  end

  local nodeBackgroundStencil = function()
    love.graphics.setShader(mask_shader)
    for _,node in pairs(self.nodes) do
      local x, y = (node.x * cellSize) + node.size/2 + tx, (node.y * cellSize) + node.size/2 + ty
      local dataKey = node.nodeValue
      local optionValue = self.nodeValueOptions[dataKey]
      -- cut-out the areas that overlap the connections
      love.graphics.setColor(0,0,0)
      local nodeBackground = self.defaultNodeImage
      local AnimationFactory = require 'components.animation-factory'
      local animation = AnimationFactory
        :newStaticSprite(optionValue and optionValue.image or self.defaultNodeImage)
      local ox, oy = animation:getOffset()
      animation:draw(
        math.floor(x), math.floor(y),
        0,
        state.scale, state.scale,
        math.floor(ox), math.floor(oy)
      )
    end
    love.graphics.setShader()
  end

  love.graphics.stencil(nodeBackgroundStencil, 'replace', 1)
  love.graphics.setStencilTest('notequal', 1)
  -- draw connections
  for nodeId,node in pairs(self.nodes) do
    for connectionNodeId in pairs(node.connections or {}) do
      local oLineWidth = love.graphics.getLineWidth()
      local connectionNode = self.nodes[connectionNodeId]
      local color = isHovered and Color.LIME or
        (
          playMode:isConnectionToSelectableNode(node, connectionNode) and
            self.colors.nodeConnection.inner or
            self.colors.nodeConnection.innerNonSelectable
        )

      local isSelectedConnection = state.selectedConnection and
        (state.selectedConnection[connectionNodeId] and state.selectedConnection[nodeId])
      local baseWidth = 1 * state.scale
      -- line outline
      love.graphics.setLineWidth(baseWidth + 4)
      if isSelectedConnection then
        love.graphics.setColor(1,1,0)
      elseif playMode:isConnectionToSelectableNode(node, connectionNode) then
        love.graphics.setColor(Color.multiplyAlpha(color, 0.1))
      else
        love.graphics.setColor(self.colors.nodeConnection.outerNonSelectable)
      end
      drawConnection(node, connectionNode)

      local isHovered = (editorModes.EDIT == _editorMode) and
        state.hoveredConnection and
        state.hoveredConnection[nodeId] and
        state.hoveredConnection[connectionNodeId]
      love.graphics.setLineWidth(baseWidth)
      if isHovered then
        love.graphics.setColor(Color.LIME)
      else
        love.graphics.setColor(color)
      end
      drawConnection(node, connectionNode)
      love.graphics.setLineWidth(oLineWidth)
    end
  end
  love.graphics.setStencilTest()

  -- -- draw nodes
  for nodeId,node in pairs(self.nodes) do
    local dataKey = node.nodeValue
    local optionValue = self.nodeValueOptions[dataKey]
    local radius = node.size/2
    local x, y = node.x * cellSize + node.size/2 + tx,
      node.y * cellSize + node.size/2 + ty

    if (editorModes.PLAY == _editorMode) or
      (editorModes.PLAY_READ_ONLY == _editorMode) or
      (editorModes.PLAY_UNSELECT_ONLY == _editorMode)
    then
      if node.selected then
        love.graphics.setColor(1,1,1)
      -- highlight selectable nodes
      elseif editorModes.PLAY == _editorMode and
          playMode:isNodeSelectable(node, self.nodes, self.nodeValueOptions) then
        love.graphics.setColor(1,1,1,math.max(math.cos(self.clock), 0.3))
      else
        love.graphics.setColor(1,1,1,0.3)
      end
      local AnimationFactory = require 'components.animation-factory'
      local sprite = optionValue and optionValue.image or self.defaultNodeImage
      local animation = AnimationFactory:newStaticSprite(sprite)
      local ox, oy = animation:getOffset()
      animation:draw(
        math.floor(x), math.floor(y),
        0,
        state.scale, state.scale,
        math.floor(ox), math.floor(oy)
      )

      if self.debug.selectionTraversal then
        if debugState.checkedNodes[nodeId] then
          love.graphics.setColor(1,1,0)
          love.graphics.circle('fill', x, y, 10)
        end

        if (debugState.firstCheckedNode == nodeId) then
          love.graphics.setColor(1,0,1)
          love.graphics.circle('fill', x, y, 10)
        end
      end
    end

    if (editorModes.EDIT == _editorMode) then
      if node.hovered then
        love.graphics.setColor(0,1,0)
      else
        love.graphics.setColor(1,0.5,0)
      end
      love.graphics.circle('fill', x, y, radius)

      if optionValue then
        debugTextLayer:add(
          optionValue.name,
          Color.WHITE,
          math.floor(x/state.scale), math.floor(y/state.scale)
        )
      end

      if state.selectedNode == nodeId then
        local oLineWidth = love.graphics.getLineWidth()
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1,1,1)
        love.graphics.circle('line', x, y, radius + 4)
        love.graphics.setLineWidth(oLineWidth)
      end
    end

    if self.debug.connectionCount then
      debugTextLayer:add(
        #F.keys(node.connections),
        Color.WHITE,
        x/state.scale, y/state.scale
      )
    end
  end

  love.graphics.pop()

  self:drawTooltip()
  drawHelpText(self)
end

function TreeEditor.final(self)
  self.autoSave:stop()
  msgBus.off(self.listeners)
  msgBus.send(msgBus.CURSOR_SET, {})
  InputContext.reset('any')
end

return Component.createFactory(TreeEditor)