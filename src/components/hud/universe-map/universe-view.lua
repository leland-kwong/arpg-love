local Component = require 'modules.component'
local dynamicRequire = require 'utils.dynamic-require'
local AnimationFactory = require 'components.animation-factory'
local overworldMapDefinition = dynamicRequire 'built.maps.overworld-map'
local F = require 'utils.functional'
local getFont = require 'components.font'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'

local state = {
  clock = 0,
  isViewShowing = false,
  mapState = {},
  hoveredPoint = nil
}

local function hasLocationBeenVisited(location)
  local locationsVisited = Component.groups.locationsVisited.getAll()
  return locationsVisited[location]
end

local function renderTextObjects(textObjects)
  for i=1, #textObjects do
    local o = textObjects[i]
    local font = getFont(o.fontfamily, o.pixelsize)
    love.graphics.setFont(font.font)
    love.graphics.setColor(Color.WHITE)
    love.graphics.print(o.text, o.x, o.y)
  end
end

local portalPointGraphic = AnimationFactory:newStaticSprite('gui-map-portal-point')
local function renderPortalPoints(portalPoints)
  for i=1, #portalPoints do
    local p = portalPoints[i]
    if state.hoveredPoint == p.id then
      love.graphics.setColor(1,1,0)
    elseif hasLocationBeenVisited(p.properties.layoutType) then
      love.graphics.setColor(1,1,1)
    else
      local c = 0.5
      love.graphics.setColor(c, c, c)
    end
    portalPointGraphic:draw(p.x, p.y)
  end
end

local function renderPortalConnectionLines(connections)
  local pixel = AnimationFactory:newStaticSprite('pixel-white-1x1')
  love.graphics.setColor(1,1,1)
  for i=1, #connections do
    local l = connections[i]
    local rad = (l.rotation * math.pi) / 180
    pixel:draw(l.x, l.y, rad, l.width, l.height)
  end
end

local function renderDebugBox(self)
  love.graphics.push()
  love.graphics.origin()

  love.graphics.setColor(1,1,0,0.5)
  love.graphics.rectangle('line', self.x, self.y, self.w, self.h)

  love.graphics.pop()
end

local function setupInteractionElements()
  local areaObjects = F.find(overworldMapDefinition.layers, function(l)
    return l.name == 'areas'
  end).objects
  local portalPoints = F.filter(areaObjects, function(o)
    return o.type == 'portalPoint'
  end)
  F.forEach(portalPoints, function(p)
    local w,h = portalPointGraphic:getWidth(), portalPointGraphic:getHeight()
    local originalX, originalY = p.x - w/2, p.y - h/2
    return Gui.create({
      x = x,
      y = y,
      id = 'portal-point-'..p.id,
      getMousePosition = function()
        local mx,my = love.mouse.getX(), love.mouse.getY()
        return mx, my
      end,
      onUpdate = function(self)
        self.scale = state.mapState.scale
        self.w, self.h = w*self.scale, h*self.scale
        local tx = state.mapState.translate
        self.x, self.y = (originalX + tx.x) * self.scale + (state.mapState.translate.zoomOffset.x * state.mapState.scale),
          (originalY + tx.y) * self.scale + (state.mapState.translate.zoomOffset.y * state.mapState.scale)
      end,
      onCreate = function(self)
        Component.addToGroup(self, 'guiPortalPoint')
      end,
      onPointerMove = function()
        if (hasLocationBeenVisited(p.properties.layoutType)) then
          state.hoveredPoint = p.id
        end
      end,
      onPointerLeave = function()
        state.hoveredPoint = nil
      end,
      render = function(self)
        -- renderDebugBox(self)
      end,
      onClick = function()
        local msgBus = require 'components.msg-bus'
        local location = {
          layoutType = p.properties.layoutType
        }
        msgBus.send('PORTAL_ENTER', location)
        msgBus.send('MAP_TOGGLE')
      end
    })
  end)
end

local function cleanupGuiElements()
  for _,c in pairs(Component.groups.guiPortalPoint.getAll()) do
    c:delete(true)
  end
end

Component.create({
  id = 'UniverseViewWatcher',
  group = 'hud',
  init = function()
  end,
  update = function(self, dt)
    state.clock = state.clock + dt
    local isViewStateChange = state.isViewShowing ~= self.previousViewState
    if isViewStateChange then
      if state.isViewShowing then
        print('showing')
        setupInteractionElements()
      else
        print('hidden')
        cleanupGuiElements()
      end
    end
    self.previousViewState = state.isViewShowing
    state.isViewShowing = false
  end
})

return function(mapState)
  state.mapState = mapState

  state.isViewShowing = true
  local textObjects = F.find(overworldMapDefinition.layers, function(l)
    return l.name == 'text'
  end).objects
  renderTextObjects(textObjects)

  local areaObjects = F.find(overworldMapDefinition.layers, function(l)
    return l.name == 'areas'
  end).objects
  renderPortalPoints(
    F.filter(areaObjects, function(o)
      return o.type == 'portalPoint'
    end)
  )

  renderPortalConnectionLines(
    F.filter(areaObjects, function(o)
      return o.type == 'connectionLine'
    end)
  )
end
