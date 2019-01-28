local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Position = require 'utils.position'
local Vec2 = require 'modules.brinevector'
local Grid = dynamicRequire 'utils.grid'
local bump = require 'modules.bump'
local msgBus = require 'components.msg-bus'
local room1 = require 'built.maps.room-1'
local F = require 'utils.functional'
local Color = require 'modules.color'
local memoize = require 'utils.memoize'
local O = require 'utils.object-utils'
local Observable = require 'modules.observable'

local gridSize = {
  w = 60,
  h = 80
}
local uiColWorld = bump.newWorld(10)

local function CreateState(initialState, options)
  options = options or {
    trackHistory = false
  }

  local stateCopy = O.deepCopy(initialState)
  local stateMt = {
    _onChange = function()
      return self
    end,
    set = function(self, k, v, ignoreHistory)
      local currentVal = self[k]
      local isNewVal = currentVal ~= v
      local shouldTrackChange = options.trackHistory and
        isNewVal and
        (not ignoreHistory) and
        (not self._logPending)
      if shouldTrackChange then
        self._logPending = true
        Observable(function()
          self._logPending = false
          self._changeHistory:push()
          return true
        end)
      end

      self[k] = v
      self._onChange(self, k, v, currentVal)

      return self
    end,
    undo = function(self)
      local prevState = self._changeHistory:back() or {}
      for k,v in pairs(prevState) do
        self:set(k, v, true)
      end
    end,
    redo = function(self)
      local nextState = self._changeHistory:forward() or {}
      for k,v in pairs(nextState) do
        self:set(k, v, true)
      end
    end,
    onChange = function(self, callback)
      self._onChange = callback
      return self
    end,

    _logPending = false,
    _changeHistory = {
      history = {},
      position = 0,
      removeEntriesAfterPosition = function(self, position)
        local i = #self.history
        while i > position do
          table.remove(self.history, i)
          i = i - 1
        end
      end,
      push = function(self)
        self:removeEntriesAfterPosition(self.position)
        table.insert(self.history, O.clone(stateCopy))
        self.position = #self.history
      end,
      back = function(self)
        local clamp = require 'utils.math'.clamp
        self.position = clamp(self.position - 1, 0, #self.history)
        return self.history[self.position]
      end,
      forward = function(self)
        local clamp = require 'utils.math'.clamp
        self.position = clamp(self.position + 1, 0, #self.history)
        return self.history[self.position]
      end
    }
  }
  stateMt.__index = stateMt
  return setmetatable(stateCopy, stateMt)
end

local state = CreateState({
  mapSize = Vec2(0, 0),
  loadDir = nil,
  saveDir = nil,
  objects = {},
  placedObjects = {} -- 2d grid of objects
}, {
  trackHistory = true
})

local uiState = CreateState({
  mousePosition = Vec2(0, 0),
  mouseGridPosition = Vec2(0, 0),
  fileStateContext = nil,
  loadedLayouts = {},
  translate = {
    startX = 0,
    startY = 0,
    dx = 0,
    dy = 0,
    x = 150,
    y = 100,

    zoomOffset = Vec2(0, 0),
  },
  scale = 1,

  hoveredObject = {},
  selectedObject = nil,
  collisions = {},
  loadedLayoutObjects = {},

  getTranslate = function(self)
    local tx = self.translate
    return tx.x + tx.dx, tx.y + tx.dy
  end,

  setSelection = function(self, object)
    self:set('selectedObject', object)
  end
})

local layoutsCanvases = {}
local gridCanvas = love.graphics.newCanvas(4096, 4096)

local function panTo(x, y)
  local tx = uiState.translate
  tx.x, tx.y = x, y
end

local collisionObjectMt = {
  offsetX = 0,
  offsetY = 0,
  selectable = false
}
collisionObjectMt.__index = collisionObjectMt
local function ColObj(props)
  return setmetatable(props, collisionObjectMt)
end

local function handlePanning(event)
  -- panning
  local tx = uiState.translate
  local scale = uiState.scale
  tx.startX = event.startX/scale
  tx.startY = event.startY/scale
  tx.dx = math.floor(event.dx/scale)
  tx.dy = math.floor(event.dy/scale)
end

local function handlePanningEnd(event)
  local state = uiState

  -- update tree translation
  local tx = state.translate
  panTo(tx.x + tx.dx, tx.y + tx.dy)
  tx.startX = 0
  tx.startY = 0
  tx.dx = 0
  tx.dy = 0
end

local function setupGridCanvas(colSpan, rowSpan)
  love.graphics.setCanvas(gridCanvas)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.clear()
  local color = 0.25
  love.graphics.setColor(color, color, color)

  for y=0, (rowSpan - 1) do
    for x=0, (colSpan - 1) do
      local renderX, renderY = x * gridSize.w + 0.5, y * gridSize.h + 0.5
      love.graphics.rectangle('line', renderX, renderY, gridSize.w, gridSize.h)
    end
  end

  love.graphics.setCanvas()
  love.graphics.pop()
end

-- Lua implementation of PHP scandir function
local function loadLayouts(directory)
  local layouts = {}
  local lfs = require 'lua_modules.lfs_ffi'
  for file in lfs.dir(directory) do
    local fullPath = directory..'\\'..file
    local mode = lfs.attributes(fullPath,"mode")
    if mode == "file" then
      -- print("found file, "..file)
      local io = require 'io'
      local fileDescriptor = io.open(fullPath)
      table.insert(
        layouts,
        {
          file = file,
          data = load(
            fileDescriptor:read('*a')
          )()
        }
      )
    end
  end
  return layouts
end

local function iterateListAsGrid(list, numCols, callback)
  for i=1, #list do
    local val = list[i]
    local x, y = Grid.getCoordinateByIndex(list, i, numCols)
    callback(val, x, y)
  end
end

local renderersByLayerType = {
  tilelayer = {
    [1] = function(x, y, w, h)
      love.graphics.setColor(1,1,1,0.1)
      love.graphics.rectangle('fill', x, y, w, h)
    end,
    [12] = function(x, y, w, h)
      love.graphics.setColor(1,1,1,0.7)
      love.graphics.rectangle('fill', x, y, w, h)
    end
  },
  objectgroup = {
    point = function(scale, obj)
      love.graphics.setColor(0,1,1)
      love.graphics.circle('fill', obj.x * scale, obj.y * scale, 2)
    end
  }
}

local loadedLayoutsContainerBox = ColObj({
  x = 0,
  y = 0,
  w = 100,
  h = love.graphics.getHeight(),
  padding = {15, 0},
  scrollY = 0,

  MOUSE_WHEEL_MOVED = function(self, ev)
    local dy = ev[2]
    local scrollSpeed = 20
    local clamp = require 'utils.math'.clamp

    local maxY = 0
    for _,obj in pairs(uiState.loadedLayoutObjects) do
      maxY = math.max(maxY, obj.y + obj.h)
    end
    self.scrollY = clamp(self.scrollY + (dy * scrollSpeed), -(maxY - self.h + self.padding[1]), 0)

    for _,obj in pairs(uiState.loadedLayoutObjects) do
      obj.offsetY = self.scrollY
      uiColWorld:update(obj, obj.x + obj.offsetX, obj.y + obj.offsetY)
    end

  end
})
uiColWorld:add(
  loadedLayoutsContainerBox,
  loadedLayoutsContainerBox.x,
  loadedLayoutsContainerBox.y,
  loadedLayoutsContainerBox.w,
  loadedLayoutsContainerBox.h
)

local updateLayouts = memoize(function (layouts, groupOrigin)
  local oBlendMode = love.graphics.getBlendMode()

  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.setColor(1,1,1)
  love.graphics.push()
  love.graphics.origin()

  local scale = 1/16
  local layouts = uiState.loadedLayouts
  local offsetY = 0

  local layoutObjects = uiState.loadedLayoutObjects
  for _,obj in pairs(layoutObjects) do
    uiColWorld:remove(obj)
  end
  layoutObjects = {}

  for i=1, #layouts do
    local l = layouts[i]
    local textHeight = 20
    local marginTop = 20

    local obj = ColObj({
      id = l.file,
      data = l.data,
      type = 'mapBlock',
      x = groupOrigin.x,
      y = groupOrigin.y + offsetY + textHeight,
      offsetX = 0,
      offsetY = 0,
      w = l.data.width,
      h = l.data.height,
      selectable = true,
      eventPriority = 2,

      MOUSE_CLICKED = function(self)
        print(self.id, self.h)
        uiState:setSelection(self)
      end
    })
    layoutObjects[obj.id] = obj
    uiColWorld:add(obj, obj.x, obj.y, obj.w, obj.h)

    local canvas = layoutsCanvases[obj.id]
    if (not canvas) then
      canvas = love.graphics.newCanvas(1000, 1000)
      layoutsCanvases[obj.id] = canvas
    end
    love.graphics.setCanvas(canvas)

    F.forEach(l.data.layers, function(layer)
      if layer.type == 'tilelayer' then
        local renderType = renderersByLayerType.tilelayer
        iterateListAsGrid(layer.data, layer.width, function(v, x, y)
          if renderType[v] then
            renderType[v](x * l.data.tilewidth * scale, y * l.data.tileheight * scale, l.data.tilewidth * scale, l.data.tileheight * scale)
          end
        end)
      elseif layer.type == 'objectgroup' then
        local renderType = renderersByLayerType.objectgroup
        F.forEach(layer.objects, function(v)
          if renderType[v.shape] then
            renderType[v.shape](scale, v)
          end
        end)
      end
    end)

    offsetY = offsetY + l.data.height + textHeight + marginTop
  end

  love.graphics.pop()
  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)

  uiState:set('loadedLayoutObjects', layoutObjects)
end)

local function renderLoadedLayoutObjects()
  love.graphics.setColor(1,1,1)
  for id,obj in pairs(uiState.loadedLayoutObjects) do
    local canvas = layoutsCanvases[id]
    love.graphics.draw(canvas, obj.x, obj.y + obj.offsetY)
  end

  love.graphics.setColor(1,1,1)
  for _,obj in pairs(uiState.loadedLayoutObjects) do
    love.graphics.print(obj.id, obj.x, obj.y - 20 + obj.offsetY)
  end
end

state:onChange(function(self, k, val, prevVal)
  local isNewVal = val ~= prevVal

  local isNewLoadDir = k == 'loadDir' and isNewVal
  if isNewLoadDir then
    local layouts = loadLayouts(val)
    uiState:set('loadedLayouts', layouts)
    updateLayouts(layouts,  {
      x = 10,
      y = 10
    })
  end

  local isNewMapSize = k == 'mapSize' and isNewVal
  if isNewMapSize then
    setupGridCanvas(state.mapSize.x, state.mapSize.y)
  end
end)
state:set('loadDir', 'C:\\Users\\lelandkwong\\Projects\\arpg-love\\src\\built\\maps')

local function renderMousePosition()
  if uiState.selectedObject then
    return
  end

  love.graphics.setColor(0,0.6,1,1)
  local mgp = uiState.mousePosition
  love.graphics.rectangle('line', mgp.x + 0.5, mgp.y + 0.5, gridSize.w, gridSize.h)
end

local inputWidth = 500

local loadedDirectoryBox = ColObj({
  id = 'loadedDirectory',
  x = love.graphics.getWidth() - 10 - inputWidth,
  y = 10,
  w = inputWidth,
  h = 30
})

uiColWorld:add(
  loadedDirectoryBox,
  loadedDirectoryBox.x,
  loadedDirectoryBox.y,
  loadedDirectoryBox.w,
  loadedDirectoryBox.h
)

local saveDirectoryBox = ColObj({
  id = 'saveDirectory',
  x = love.graphics.getWidth() - 10 - inputWidth,
  y = loadedDirectoryBox.y + 35,
  w = inputWidth,
  h = 30
})

uiColWorld:add(
  saveDirectoryBox,
  saveDirectoryBox.x,
  saveDirectoryBox.y,
  saveDirectoryBox.w,
  saveDirectoryBox.h
)

local function guiPrint(text, x, y)
  local getFont = require 'components.font'
  love.graphics.setFont(getFont.debug.font)
  love.graphics.print(text, x, y)
end

local function renderLoadDirectoryBox()
  local isHovered = F.find(uiState.collisions, function(c)
    return c.other.id == loadedDirectoryBox.id
  end) ~= nil
  if isHovered then
    love.graphics.setColor(1,1,0)
  else
    love.graphics.setColor(1,1,1)
  end
  local box = loadedDirectoryBox
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', box.x - 0.5, box.y - 0.5, box.w, box.h)
  guiPrint(state.loadDir or 'drag folder to load Tiled maps', box.x + 3, box.y + 5)
end

local function renderSaveDirectoryBox()
  local isHovered = F.find(uiState.collisions, function(c)
    return c.other.id == saveDirectoryBox.id
  end) ~= nil
  if isHovered then
    love.graphics.setColor(1,1,0)
  else
    love.graphics.setColor(1,1,1)
  end
  local box = saveDirectoryBox
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', box.x - 0.5, box.y - 0.5, box.w, box.h)
  guiPrint(state.saveDir or 'drag folder to save to', box.x + 3, box.y + 5)
end

local function renderGuiElements()
  renderLoadDirectoryBox()
  renderSaveDirectoryBox()
end

local function getFileStateContext(dir)
  local context = F.find(uiState.collisions, function(c)
    local otherId = c.other.id
    return otherId == loadedDirectoryBox.id or otherId == saveDirectoryBox.id
  end)

  local contexts = {
    [loadedDirectoryBox.id] = 'loadDir',
    [saveDirectoryBox.id] = 'saveDir'
  }

  return contexts[context.other.id]
end

function love.directorydropped(dir)
  local fileStateContext = getFileStateContext()
  if fileStateContext then
    uiState:set(fileStateContext, dir)
  end
end

local getNativeMousePos = dynamicRequire 'repl.shared.native-cursor-position'
local function getCursorPos()
  local pos = getNativeMousePos()
  local windowX, windowY = love.window.getPosition()
  return {
    x = pos.x - windowX,
    y = pos.y - windowY
  }
end

local function renderHoveredObjectBox()
  local o = uiState.hoveredObject
  if o then
    love.graphics.setColor(1,1,0)
    love.graphics.rectangle('line', o.x + o.offsetX + 0.5, o.y + o.offsetY + 0.5, o.w, o.h)
  end
end

local function renderSelectedObject()
  local o = uiState.selectedObject
  if (not o) then
    return
  end

  local mp = uiState.mousePosition
  local mx, my = mp.x, mp.y
  if o.type == 'mapBlock' then
    love.graphics.setColor(1,1,1,0.6)
    local canvas = layoutsCanvases[o.id]
    love.graphics.draw(canvas, mx, my)
  end
end

local indexOffset = 1
local function placeObject()
  local mgp = uiState.mouseGridPosition
  local x, y = mgp.x + indexOffset, mgp.y + indexOffset
  local currentObj = Grid.get(state.placedObjects, x, y)
  local isNewObject = (currentObj and currentObj.referenceId) ~= uiState.selectedObject.id
  if (not isNewObject) then
    return
  end

  local objectState = O.deepCopy(state.placedObjects)
  Grid.set(objectState, x, y, {
    id = Component.newId(),
    referenceId = uiState.selectedObject.id,
    data = uiState.selectedObject
  })
  state:set('placedObjects', objectState)
end

local function renderPlacedObjects()
  Grid.forEach(state.placedObjects, function(o, x, y)
    local tx, ty = uiState:getTranslate()
    local actualX, actualY = (x - indexOffset) * gridSize.w + tx, (y - indexOffset) * gridSize.h + ty
    local data = o.data
    if data.type == 'mapBlock' then
      love.graphics.setColor(1,1,1)
      local canvas = layoutsCanvases[data.id]
      love.graphics.draw(canvas, actualX, actualY)
    end
  end)
end

local mouseCollision = {}
uiColWorld:add(mouseCollision, 0, 0, 1, 1)

local function updateUiCollisions(mouseX, mouseY)
  local _, _, cols, len = uiColWorld:move(mouseCollision, mouseX, mouseY, function()
    return 'cross'
  end)
  table.sort(cols, function(a, b)
    local ep1 = a.other.eventPriority or 1
    local ep2 = b.other.eventPriority or 1
    return ep1 > ep2
  end)
  uiState:set('collisions', cols)
end

Component.create({
  id = 'LayoutEditor',
  group = 'gui',

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

    state:set('mapSize', Vec2(20, 10))

    Gui.create({
      x = 0,
      y = 0,
      inputContext = 'editorBase',
      scale = 1,
      onCreate = function(self)
        Gui.setFocus(self)
      end,
      onPointerMove = function(self, ev)
        local pos = getCursorPos()
        local translateX, translateY = uiState:getTranslate()
        local clamp = require 'utils.math'.clamp
        local gridPos = Vec2(
          clamp(math.floor((pos.x - translateX)/gridSize.w), 0, state.mapSize.x - 1),
          clamp(math.floor((pos.y - translateY)/gridSize.h), 0, state.mapSize.y - 1)
        )
        local posX, posY = (gridPos.x * gridSize.w), (gridPos.y * gridSize.h)
        local round = require 'utils.math'.round
        uiState:set('mousePosition', Vec2(posX + translateX, posY + translateY))
        uiState:set('mouseGridPosition', Vec2(gridPos.x, gridPos.y))

        updateUiCollisions(pos.x, pos.y)

        msgBus.send('CURSOR_SET', { type = uiState.panning and 'move' or 'default' })
      end,
      onClick = function(self)
      end,
      onKeyPress = function(self, ev)
        if ev.key == 'escape' then
          uiState:set('selectedObject', nil)
        end

        local inputState = require 'main.inputs.keyboard-manager'.state
        local keysPressed = inputState.keyboard.keysPressed
        local hasCtrlModifier = keysPressed.lctrl or
          keysPressed.rctrl
        if hasCtrlModifier then
          if 'z' == ev.key then
            if keysPressed.lshift or keysPressed.rshift then
              state:redo()
            else
              state:undo()
            end
          end
        end
      end,
      onPointerDown = function()
        if (uiState.hoveredObject or uiState.panning) then
          return
        end
        placeObject()
      end,
      onUpdate = function(self, dt)
        self.w, self.h = love.graphics.getWidth(),
          love.graphics.getHeight()
      end,
      render = function(self)
        love.graphics.push()
        love.graphics.origin()

        love.graphics.push()
        love.graphics.translate(uiState:getTranslate())
        love.graphics.setColor(1,1,1)
        love.graphics.draw(gridCanvas)
        love.graphics.pop()

        renderGuiElements()
        renderLoadedLayoutObjects()
        renderPlacedObjects()
        renderMousePosition()
        renderSelectedObject()
        renderHoveredObjectBox()

        love.graphics.pop()
      end
    }):setParent(self)

    self.listeners = {
      msgBus.on('*', function(ev, msgType)
        local hoveredObject = nil
        local uiCollisions = uiState.collisions
        local preventBubbleEvents = {}

        -- handle ui events
        for i=1, #uiCollisions do

          local c = uiCollisions[i]

          hoveredObject = hoveredObject or c.other

          if (not preventBubbleEvents[msgType]) then
            local eventHandler = c.other[msgType]
            if eventHandler then
              local returnVal = eventHandler(c.other, ev) or O.EMPTY
              if returnVal.stopPropagation then
                preventBubbleEvents[msgType] = true
              end
            end
          end

          if (not preventBubbleEvents.MOUSE_MOVE) then
            local mouseMoveHandler = c.other.MOUSE_MOVE
            if mouseMoveHandler then
              local returnVal = mouseMoveHandler(c.other, ev) or O.EMPTY
              if returnVal.stopPropagation then
                preventBubbleEvents.MOUSE_MOVE = true
              end
            end
          end
        end

        uiState:set('hoveredObject', hoveredObject)
      end),

      msgBus.on('MOUSE_DRAG', function(ev)
        if love.keyboard.isDown('space') then
          handlePanning(ev)
        else
          handlePanningEnd(ev)
        end
      end),

      msgBus.on('MOUSE_DRAG_END', function(ev)
        handlePanningEnd(ev)
      end)
    }
  end,

  update = function(self, dt)
    uiState:set('panning', love.keyboard.isDown('space'))
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})