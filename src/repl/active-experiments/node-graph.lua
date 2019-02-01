local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'
local Grid = require 'utils.grid'
local Font = require 'components.font'
local getTextSize = require 'repl.libs.get-text-size'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local GuiContext = dynamicRequire 'repl.libs.gui'
local camera = require 'components.camera'
local Node = dynamicRequire 'utils.node-graph'
local renderGraph = dynamicRequire 'repl.components.node-graph.render-graph'
local buildUniverse = dynamicRequire 'repl.components.node-graph.build-universe'

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

local actions = require 'repl.components.node-graph.actions'(state)

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

    self.graph = buildUniverse(actions, Node)

    local guiNodes = {}
    self.guiNodes = guiNodes
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

    renderGraph(self.graph, state.distScale, state)
    self.renderGuiDebug()

    love.graphics.pop()
  end,

  final = function(self)
    Gui:destroy()
  end
})