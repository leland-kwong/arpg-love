local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local BeamStrike = require 'components.abilities.beam-strike'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'
local bump = require 'modules.bump'

local mouseCollisionWorld = bump.newWorld(32)
local mouseCollisionObject = {}
local mouseCollisionSize = 24
mouseCollisionWorld:add(mouseCollisionObject, 0, 0, mouseCollisionSize, mouseCollisionSize)

--[[
  Instructions:

  click - place a node
  click node - selects node. If a node is already selected, creates a connection between both nodes
]]

--[[
  TODO:
  - delete connection by selecting it and pressing delete
]]

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font
})

local PassiveTree = {
  debug = {
    connectionCount = true,
  }
}

local hoveredNode = nil
local selectedNode = nil
local hoveredConnection = nil
local selectedConnection = nil
local mx, my = 0,0

local function getMode()
  if (not hoveredNode) and (not hoveredConnection) then
    return 'NODE_CREATE'
  end

  if hoveredNode then
    return 'NODE_SELECTION'
  end

  if hoveredConnection then
    return 'CONNECTION_SELECTION'
  end
end

local function placeNode(root, x, y)
  local size = 40
  local node = Gui.create({
    x = x - size/2,
    y = y - size/2,
    width = size,
    height = size,
    scale = 1,
    connections = {},
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
    end,
    onClick = function(self)
      local selection = selectedNode
      selectedNode = nil
      local shouldDrawConnection = not not selection
      local selfId = self:getId()
      if shouldDrawConnection then
        local selectedGuiNode = Component.get(selection)
        local duplicateConnection = self.connections[selection]
        if duplicateConnection then
          consoleLog('duplicate connection detected')
          return
        end

        local lineData = {} -- if more points are added, we define a bezier curve
        self.connections[selection] = lineData
        selectedGuiNode.connections[selfId] = lineData

        return
      end
      selectedNode = self:getId()
    end
  })

  return node:getId()
end

function PassiveTree.init(self)
  local root = self
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  Component.get('mainMenu'):delete(true)

  love.mouse.setCursor()

  Component.addToGroup(self, 'gui')
  self.nodes = {}

  msgBus.on(msgBus.MOUSE_CLICKED, function(event)
    if hoveredNode then
      return
    end

    local mode = getMode()
    local x, y, button = unpack(event)

    if 'NODE_CREATE' == mode then
      -- place node
      if button == 1 then
        self.nodes[placeNode(root, x, y)] = true
      end
    end

    if 'CONNECTION_SELECTION' == mode then
      if button == 1 then
        selectedConnection = hoveredConnection
      end
    end
  end)

  msgBus.on(msgBus.KEY_PRESSED, function(event)
    if event.key == 'escape' and selectedNode then
      selectedNode = nil
    end

    local deleteNode = event.key == 'delete' and selectedNode
    if deleteNode then
      -- remove connections
      local guiNode = Component.get(selectedNode)
      for toNodeId in pairs(guiNode.connections) do
        local toGuiNode = Component.get(toNodeId)
        toGuiNode.connections[selectedNode] = nil
      end

      -- remove node from list
      self.nodes[selectedNode] = nil
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
end

function PassiveTree.draw(self)
  love.graphics.push()
  love.graphics.origin()

  -- draw connections
  for nodeId in pairs(self.nodes) do
    local node = Component.get(nodeId)

    for connectionNodeId in pairs(node.connections or {}) do
      local oLineWidth = love.graphics.getLineWidth()
      local connectionNode = Component.get(connectionNodeId)

      if selectedConnection == connectionNodeId then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(1,1,1)
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

    if self.debug.connectionCount then
      local F = require 'utils.functional'
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

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    local msgBusMainMenu = require 'components.msg-bus-main-menu'
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Factory
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})