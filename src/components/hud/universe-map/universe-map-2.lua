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
local Graph = require 'utils.graph'
local renderGraph = dynamicRequire 'components.hud.universe-map.render-graph'
local buildUniverse = dynamicRequire 'components.hud.universe-map.build-universe'
local MenuManager = require 'modules.menu-manager'
local Enum = require 'utils.enum'
local config = require 'config.config'

local mapViews = Enum(
  'UNIVERSE',
  'LOCAL'
)

local state = {
  distScale = 1,
  translate = Vec2(),
  unlockedNodes = {
    ['1-1'] = true,
    ['1-2'] = true,
    ['1-3'] = true
  },
  hoveredNode = nil,
  nodeStyles = {},
  graph = nil,
  view = mapViews.UNIVERSE
}

local actions = require 'components.hud.universe-map.actions'(state)

local function createGraphNodeGuiElement(Gui, node)
  local nodeRef = Graph:getSystem('universe'):getNode( node)
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

local oy = 10
local viewToggleGraphic = AnimationFactory:newStaticSprite('gui-map-gui-view-toggle')
local function getViewTogglePosition()
  local Position = require 'utils.position'
  local w1, h1 = viewToggleGraphic:getWidth(), viewToggleGraphic:getHeight()
  local camera = require 'components.camera'
  local w2, h2 = camera:getSize(true)
  local ox = Position.boxCenterOffset(w1, h1, w2, h2)
  return ox, oy
end

local legendGraphic = AnimationFactory:newStaticSprite('gui-map-gui-legend')
local function getLegendPosition()
  local camera = require 'components.camera'
  local w2 = camera:getSize(true)
  return w2 - legendGraphic:getWidth() - 50, oy
end

local function getNextPlayerPosition(self)
  local playerRef = Component.get('PLAYER')
  if playerRef then
    return playerRef.x, playerRef.y
  end

  return 0,0
end

local function switchView(self, view)
  if (mapViews.UNIVERSE == view) then
    state.distScale = 2
    actions.panTo(200, 160)
  elseif (mapViews.LOCAL == view) then
    local playerX, playerY = getNextPlayerPosition(self)
    local camera = require 'components.camera'
    local w,h = camera:getSize(true)
    state.distScale = 1
    actions.panTo((w/2 - playerX/config.gridSize) * camera.scale, (h/2 - playerY/config.gridSize) * camera.scale)
  end
  state.view = view
end

local function setupViewToggleButtons(parent)
  local function ToggleButton(x, y, w, h, value)
    local camera = require 'components.camera'
    return parent.Gui({
      -- debug = true,
      x = x * camera.scale,
      y = y * camera.scale,
      w = w * camera.scale,
      h = h * camera.scale,
      eventPriority = 3,
      MOUSE_CLICKED = function(self)
        state.view = value
        switchView(parent, state.view)
      end,
      render = function(self)
        local isSelected = (state.view == value)
        local Color = require 'modules.color'
        if self.hovered or isSelected then
          if isSelected then
            love.graphics.setColor(Color.rgba255(44, 232, 245))
          else
            love.graphics.setColor(Color.multiplyAlpha(Color.WHITE, 0.5))
          end
          local selectedIndicator = AnimationFactory:newStaticSprite('gui-selected-indicator')
          love.graphics.push()
          love.graphics.translate(-self.x/camera.scale, -self.y/camera.scale)
          selectedIndicator:draw((self.x) + 2, self.y)
          love.graphics.pop()
        end
        if self.debug then
          self:renderDebug()
        end
      end,
      renderDebug = function(self)
        love.graphics.push()
        love.graphics.origin()

        love.graphics.setColor(1,1,0,0.3)
        love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

        love.graphics.pop()
      end
    })
  end

  local x, y = getViewTogglePosition(), oy + 22
  local buttonWidth = 48
  local toggleButtons = {
    ToggleButton(x, y, buttonWidth, 20, mapViews.UNIVERSE),
    ToggleButton(x + buttonWidth, y, buttonWidth, 20,  mapViews.LOCAL)
  }
  parent.renderToggleViewButtons = function()
    love.graphics.setColor(1,1,1)
    viewToggleGraphic:draw(getViewTogglePosition())
    legendGraphic:draw(getLegendPosition())
    for i=1, #toggleButtons do
      toggleButtons[i]:render()
    end
  end
end

local Factory = Component.createFactory({
  group = 'hud',
  init = function(self)
    MenuManager.clearAll()
    MenuManager.push(self)

    switchView(self, state.view)
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

    setupViewToggleButtons(self)

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

    state.graph:forEachLink(function(_, link)
      local node1, node2 = link.nodes[1], link.nodes[2]
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

    if state.view == mapViews.UNIVERSE then
      renderGraph(state.graph, camera.scale, state.distScale, state)
    elseif state.view == mapViews.LOCAL then
      love.graphics.scale(state.distScale)
      local PlayerPositionIndicator = require 'components.hud.player-position-indicator'
      local minimapRef = Component.get('miniMap')
      local gridSize = 16
      if minimapRef then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(minimapRef.canvas, 0, 0)
        love.graphics.draw(minimapRef.dynamicBlocksCanvas, 0, 0)

        love.graphics.setColor(1,1,1)
        local playerX, playerY = getNextPlayerPosition(self)
        PlayerPositionIndicator(
          playerX/gridSize, playerY/gridSize, self.clock
        )
      end
    end
    self.renderGuiDebug()

    love.graphics.pop()

    self.renderToggleViewButtons()
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

Component.create({
  id = 'UniverseMapInit',
  group = 'hud',
  init = function(self)
    local ref = Component.get('UniverseMap')
    if ref then
      Factory.create(ref.initialProps)
    end

    self.listeners = {
      msgBus.on('MAP_TOGGLE', function(enabled)
        local ref = Component.get('UniverseMap')
        if ref then
          ref:delete(true)
        else
          Factory.create({
            id = 'UniverseMap',
          })
        end
      end)
    }
  end,
  update = function()
    -- local globalState = require 'main.global-state'
    -- print(globalState.activeLevel)
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})