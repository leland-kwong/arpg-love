local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local Vec2 = require 'modules.brinevector'
local ser = require 'utils.ser'
local Grid = dynamicRequire 'utils.grid'
local Font = require 'components.font'
local getTextSize = require 'repl.libs.get-text-size'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local GuiContext = dynamicRequire 'repl.libs.gui'
local camera = require 'components.camera'
local Node = dynamicRequire 'utils.graph'.Node
local renderGraph = dynamicRequire 'components.hud.universe-map.render-graph'
local buildUniverse = dynamicRequire 'components.hud.universe-map.build-universe'
local MenuManager = require 'modules.menu-manager'

local state = {
  distScale = 1,
  translate = Vec2(0, 20),
  unlockedNodes = {
    [1] = true,
    [2] = true,
    [3] = true
  },
  hoveredNode = nil,
  nodeStyles = {},
  graph = nil
}

local actions = dynamicRequire 'components.hud.universe-map.actions'(state)

local function createGraphNodeGuiElement(Gui, node)
  local nodeRef = Node:getSystem('universe'):get( node)
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
    MOUSE_CLICKED = function(self)
      actions.buildLevel(node)
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

return Component.createFactory({
  group = 'hud',
  init = function(self)
    MenuManager.clearAll()
    MenuManager.push(self)

    self.Gui = GuiContext()

    -- full-screen event handler
    self.Gui({
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

    state.graph = buildUniverse(actions)

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

    state.graph:forEach(function(link)
      local node1, node2 = link[1], link[2]
      if (not guiNodes[node1]) then
        guiNodes[node1] = createGraphNodeGuiElement(self.Gui, node1)
      end
      if (not guiNodes[node2]) then
        guiNodes[node2] = createGraphNodeGuiElement(self.Gui, node2)
      end
    end)

    msgBus.send('CURSOR_SET', { type = 'default' })
  end,

  update = function(self, dt)
    self.Gui:update(dt)
    self.updateGuiNodes(dt)

    self.clock = (self.clock or 0) + dt
    if self.clock > 0.4 then
    end
  end,

  draw = function(self)

    love.graphics.push()
    love.graphics.origin()

    -- draw background
    love.graphics.setColor(0,0,0,0.8)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.translate(state.translate.x, state.translate.y)
    love.graphics.scale(camera.scale)

    renderGraph(state.graph, camera.scale, state.distScale, state, true)
    self.renderGuiDebug()

    love.graphics.pop()
  end,

  final = function(self)
    self.Gui:destroy()
    msgBus.send('CURSOR_SET', { type = 'target' })
    MenuManager.pop()
  end,

  drawOrder = function()
    return 10
  end,
})