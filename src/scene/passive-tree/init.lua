local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local BeamStrike = require 'components.abilities.beam-strike'
local Gui = require 'components.gui.gui'
local GuiText = require 'components.gui.gui-text'

local debugTextLayer = GuiText.create({
  font = require 'components.font'.primary.font
})

local PassiveTree = {
  debug = {
    connectionCount = true
  }
}

local hoveredNode = nil
local selectedNode = nil

function PassiveTree.init(self)
  msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  Component.get('mainMenu'):delete(true)

  love.mouse.setCursor()

  Component.addToGroup(self, 'gui')
  self.nodes = {}

  msgBus.on(msgBus.MOUSE_CLICKED, function(event)
    if hoveredNode then
      return
    end

    local x, y, button = unpack(event)
    -- place node
    if button == 1 then
      local size = 40
      local node = Gui.create({
        x = x,
        y = y,
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

            self.connections[selection] = true
            selectedGuiNode.connections[selfId] = true

            return
          end
          selectedNode = self:getId()
        end
      })
      self.nodes[node:getId()] = node
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
      selectedNode = nil
    end
  end)
end

function PassiveTree.update(self, dt)
end

function PassiveTree.draw(self)
  love.graphics.push()
  love.graphics.origin()

  -- draw connections
  for nodeId in pairs(self.nodes) do
    local node = Component.get(nodeId)

    for nodeId in pairs(node.connections or {}) do
      local oLineWidth = love.graphics.getLineWidth()
      love.graphics.setLineWidth(4)
      local connectionNode = Component.get(nodeId)
      love.graphics.setColor(1,1,1)
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
      local Color = require 'modules.color'
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