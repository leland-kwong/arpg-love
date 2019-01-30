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
local getFont = require 'components.font'
local ColObj = dynamicRequire 'repl.components.level-editor.libs.collision'
local ActionSystem = dynamicRequire 'repl.components.level-editor.libs.action-system'
local constants = dynamicRequire 'repl.components.level-editor.constants'
local states = dynamicRequire 'repl.components.level-editor.states'
local filterCall = require 'utils.filter-call'

local state = states.state
local uiState = states.uiState

local editorModes = constants.editorModes

local gridSize = {
  w = 20,
  h = 20
}
local uiColWorld = bump.newWorld(32)

local function getTextSize(text, font)
  local GuiText = require 'components.gui.gui-text'
  return GuiText.getTextSize(text, font)
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

local function resetTextBoxClock()
  uiState:set('textBoxCursorClock', math.pi)
end

local function TextBox(props, colWorld)
  local fontStyle = getFont.debug.font
  local padding = props.padding or 5
  local textBox = ColObj({
    id = Component.newId(),
    x = 0,
    y = 0,
    w = 150,
    h = select(2, getTextSize('foo', fontStyle)) + (padding*2),
    text = props.text,
    padding = padding,
    charCollisions = {},
    cursorPosition = 1,
    selectionRange = Vec2(0,0),
    updateCharCollisions = function(self)
      if self.previousText == self.text then
        return
      end
      local parent = self
      local offsetX = 0
      for _,c in ipairs(self.charCollisions) do
        ColObj:remove(c.id)
      end
      self.charCollisions = {}
      local posX, posY = ColObj:getPosition(self.id)

      -- add an extra space at the end so we can handle range selection easier
      local collisionText = self.text..' '

      for i=1, #collisionText do
        local char = string.sub(collisionText, i, i)
        local charWidth, charHeight = getTextSize(char, fontStyle)
        local collision = ColObj({
          id = 'char-'..i..'-'..self.id,
          index = i,
          type = 'textInputCharacter',
          x = posX + offsetX,
          y = posY,
          w = charWidth,
          h = charHeight + (parent.padding * 2),
          MOUSE_PRESSED = function(self, ev)
            local presses = ev[5]
            local isDoubleClick = presses % 2 == 0
            if isDoubleClick then
              parent:setRange(1, #parent.text + 1)
              return {
                stopPropagation = true
              }
            end

            local mousePos = getCursorPos()
            local round = require 'utils.math'.round
            local x = ColObj:getPosition(self.id)
            local w = ColObj:getSize(self.id)
            local isLeftEdge = (mousePos.x - x)/w < 0.4
            local indexAdjust = isLeftEdge and -1 or 0

            msgBus.send('SET_TEXT_INPUT', true)
            parent:setRange(i + indexAdjust, i + indexAdjust)

            return {
              stopPropagation = true
            }
          end,
        }, colWorld)
        table.insert(self.charCollisions, collision)
        offsetX = offsetX + charWidth
      end

      self.previousText = self.text
    end,
    setRange = function(self, _start, _end)
      local clamp = require 'utils.math'.clamp
      local max = #self.text + 1
      _start = clamp(_start, 1, max)
      _end = _end and clamp(_end, _start, max) or _start
      self.selectionRange = Vec2(_start, _end)
      resetTextBoxClock()
    end,
    MOUSE_PRESSED = function(self)
      local mousePos = getCursorPos()
      local x = ColObj:getPosition(self.id)
      local w = ColObj:getSize(self.id)
      local isBeginning = (mousePos.x - x)/w < 0.2

      if isBeginning then
        self:setRange(1)
        return
      end

      local endOfText = #self.text + 1
      self:setRange(endOfText)
    end,
    MOUSE_MOVE = function(self)
      self:updateCharCollisions()
    end,
    GUI_TEXT_INPUT = function(self, nextChar)
      local rangeLength = math.abs(self.selectionRange.x - self.selectionRange.y)
      if rangeLength > 0 then
        self.text = (string.sub(self.text, 1, self.selectionRange.x - 1) or '') .. (string.sub(self.text, self.selectionRange.y) or '')
        self.text = self.text .. nextChar
      else
        self.text = (string.sub(self.text, 1, self.selectionRange.x - 1) or '') .. nextChar .. (string.sub(self.text, self.selectionRange.y) or '')
      end
      self:setRange(self.selectionRange.x + 1, self.selectionRange.x + 1)
      self:updateCharCollisions()
      resetTextBoxClock()
    end,
    KEY_DOWN = function(self, ev)
      local rangeLength = math.abs(self.selectionRange.x - self.selectionRange.y)
      if 'backspace' == ev.key then
        local endFrag = (string.sub(self.text, self.selectionRange.y) or '')
        local isSelection = rangeLength > 0
        if isSelection then
          local startFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or '')
          self.text = startFrag .. endFrag
          self:setRange(self.selectionRange.x)
        elseif self.selectionRange.x > 1 then
          local startFrag = (string.sub(self.text, 1, self.selectionRange.x - 2) or '')
          self.text = startFrag .. endFrag
          self:setRange(self.selectionRange.x - 1)
        end
      elseif 'delete' == ev.key then
        local isSelection = rangeLength > 0
        if isSelection then
          local startFrag, endFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or ''),
            (string.sub(self.text, self.selectionRange.y) or '')
          self.text = startFrag .. endFrag
          self:setRange(self.selectionRange.x)
        else
          local startFrag, endFrag = (string.sub(self.text, 1, self.selectionRange.x - 1) or ''),
            (string.sub(self.text, self.selectionRange.y + 1) or '')
          self.text = startFrag .. endFrag
          self:setRange(self.selectionRange.x)
        end
      elseif 'left' == ev.key then
        if rangeLength > 0 then
          self:setRange(self.selectionRange.x)
        else
          self:setRange(self.selectionRange.x - 1)
        end
      elseif 'right' == ev.key then
        if rangeLength > 0 then
          self:setRange(self.selectionRange.y)
        else
          self:setRange(self.selectionRange.x + 1)
        end
      elseif 'home' == ev.key then
        self:setRange(1)
      elseif 'end' == ev.key then
        self:setRange(#self.text + 1)
      end
    end,
    MOUSE_DRAG = function(self, ev)
      local x,y,w,h = ev.startX, ev.startY, math.abs(ev.dx), math.max(1, ev.dy)
      if w <= 0 then
        return
      end
      if ev.dx < 0 then
        x = x + ev.dx
      end
      local items, len = colWorld:queryRect(x, y, w, h, function(item)
        return item.type == 'textInputCharacter'
      end)
      if len > 0 then
        table.sort(items, function(a, b)
          return a.index < b.index
        end)
        self:setRange(
          items[1].index,
          items[#items].index
        )
      end
    end
  }, colWorld)
  return textBox
end

local actions = ActionSystem()
actions:addActions({
  LAYER_CREATE = function()
    local nextState = O.clone(state.placedObjects)
    local layerId = Component.newId()
    nextState[layerId] = {}

    -- state:set('placedObjects', nextState)
    local layersListCopy = O.clone(state.layersList)
    table.insert(layersListCopy, {
      id = layerId,
      label = 'layer-'..layerId
    })
    state:set('layersList', layersListCopy)
  end,

  LAYER_SELECT = function(layerId)
    uiState:set('activeLayer', layerId)
  end,

  EDITOR_MODE_SET = function(mode)
    if not editorModes[mode] then
      error('invalid mode', mode)
    end
    uiState:set('editorMode', mode)
  end,

  -- selection must be a 2-d array
  SELECTION_SET = function(selection)
    uiState:set('selection', selection)
  end,

  SELECTION_CLEAR = function()
    uiState:set('selection', nil)
    uiState:set('gridSelection', nil)
  end,

  GRID_SELECTION_SET = function(selection)
    uiState:set('gridSelection', selection)
  end,

  PLACED_OBJECTS_ERASE = function(objectsGridToErase)
    if (not objectsGridToErase) then
      return
    end
    local nextObjectState = O.deepCopy(state.placedObjects)
    Grid.forEach(objectsGridToErase, function(_, x, y)
      Grid.set(nextObjectState, x, y, nil)
    end)
    state:set('placedObjects', nextObjectState)
  end
})

local layoutsCanvases = {}
local gridCanvas = love.graphics.newCanvas(4096, 4096)
local layersListCanvas = love.graphics.newCanvas(400, 1000)

local function panTo(x, y)
  local tx = uiState.translate
  tx.x, tx.y = x, y
end

local function guiPrint(text, x, y)
  love.graphics.setFont(getFont.debug.font)
  love.graphics.print(text, x, y)
end

local activeTextBox = TextBox({
  text = 'foobar'
}, uiColWorld)
ColObj:setTranslate(activeTextBox.id, 300, 200)

local function renderActiveTextBox()
  local b = activeTextBox
  local x,y = ColObj:getPosition(b.id)
  local padding = 6

  love.graphics.setColor(0,0,0,0.9)
  love.graphics.rectangle('fill', x + 0.5, y + 0.5, b.w, b.h)

  love.graphics.setColor(1,1,1,0.5)
  love.graphics.rectangle('line', x + 0.5, y + 0.5, b.w, b.h)

  -- render selection range
  local rangeStartBox, rangeEndBox = b.charCollisions[b.selectionRange.x],
    b.charCollisions[b.selectionRange.y]
  if rangeStartBox then
    local isSingleCursor = rangeStartBox == rangeEndBox
    local x,y,w,h = rangeStartBox.x,
      rangeStartBox.y,
      isSingleCursor and 1 or math.abs(rangeEndBox.x - rangeStartBox.x),
      rangeStartBox.h

    if isSingleCursor then
      local opacity = math.floor(math.sin(uiState.textBoxCursorClock * 7)) * -1
      love.graphics.setColor(1,1,1,opacity)
    else
      love.graphics.setColor(0,0.3,1)
    end
    love.graphics.rectangle('fill', x + padding, y, w, h)
  end

  love.graphics.setColor(1,1,1)
  guiPrint(b.text, x + padding, y + padding)
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

local function updateGridCanvas(colSpan, rowSpan)
  love.graphics.setCanvas(gridCanvas)
  love.graphics.push()
  love.graphics.origin()
  love.graphics.clear()
  local color = 0.2
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

local layersContainerWidth = 150
local layersContainerY = 100
local layersContainerBox = ColObj({
  id = 'layersContainerBox',
  x = love.graphics.getWidth() - layersContainerWidth - 1,
  y = layersContainerY,
  w = layersContainerWidth,
  h = love.graphics.getHeight() - layersContainerY - 35
}, uiColWorld)

local function updateLayersListUi()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.setCanvas(layersListCanvas)
  love.graphics.clear()

  love.graphics.setColor(1,1,1)
  local offsetY = 0
  for i=1, #state.layersList do
    local l = state.layersList[i]

    local layerObj = ColObj({
      id = l.id,
      x = layersContainerBox.x,
      y = layersContainerBox.y + offsetY,
      w = layersContainerBox.w,
      h = 20
    }, uiColWorld)

    guiPrint(
      l.label,
      0,
      offsetY
    )

    offsetY = offsetY + layerObj.h
  end

  love.graphics.pop()
  love.graphics.setCanvas()
end

local function renderLayersList()
  love.graphics.setColor(1,1,1)
  love.graphics.draw(layersListCanvas, layersContainerBox.x, layersContainerBox.y)
end

local function iterateListAsGrid(list, numCols, callback)
  for i=1, #list do
    local val = list[i]
    local x, y = Grid.getCoordinateByIndex(list, i, numCols)
    callback(val, x, y)
  end
end

local renderersByTiledLayerType = {
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
  id = 'loadedLayoutsContainerBox',
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
      ColObj:setTranslate(obj.id, nil, self.scrollY)
    end
  end
}, uiColWorld)

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
    ColObj:remove(obj.id)
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
      w = l.data.width,
      h = l.data.height,
      selectable = true,
      eventPriority = 2,

      MOUSE_MOVE = function(self)
        actions:send('EDITOR_MODE_SET', editorModes.SELECT)
      end
    }, uiColWorld)
    layoutObjects[obj.id] = obj

    local canvas = layoutsCanvases[obj.id]
    if (not canvas) then
      canvas = love.graphics.newCanvas(1000, 1000)
      layoutsCanvases[obj.id] = canvas
    end
    love.graphics.setCanvas(canvas)

    F.forEach(l.data.layers, function(layer)
      if layer.type == 'tilelayer' then
        local renderType = renderersByTiledLayerType.tilelayer
        iterateListAsGrid(layer.data, layer.width, function(v, x, y)
          if renderType[v] then
            renderType[v](x * l.data.tilewidth * scale, y * l.data.tileheight * scale, l.data.tilewidth * scale, l.data.tileheight * scale)
          end
        end)
      elseif layer.type == 'objectgroup' then
        local renderType = renderersByTiledLayerType.objectgroup
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
    guiPrint(obj.id, obj.x, obj.y - 20 + obj.offsetY)
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

  local layersListChanged = k == 'layersList' and isNewVal
  if layersListChanged then
    updateLayersListUi(val)
  end

  local isNewMapSize = k == 'mapSize' and isNewVal
  if isNewMapSize then
    updateGridCanvas(state.mapSize.x, state.mapSize.y)
  end
end)
state:set('loadDir', 'C:\\Users\\lelandkwong\\Projects\\arpg-love\\src\\built\\maps')

local function renderGridPosition()
  if uiState.selection then
    return
  end

  local style = 'line'
  if editorModes.ERASE == uiState.editorMode then
    love.graphics.setColor(1,1,1,0.15)
    style = 'fill'
  else
    love.graphics.setColor(0,0.6,1,1)
  end
  local mgp = uiState.mousePosition
  love.graphics.rectangle(style, mgp.x + 0.5, mgp.y + 0.5, gridSize.w, gridSize.h)
end

local inputWidth = 500

local loadedDirectoryBox = ColObj({
  id = 'loadedDirectory',
  x = love.graphics.getWidth() - 10 - inputWidth,
  y = 10,
  w = inputWidth,
  h = 30
}, uiColWorld)

local saveDirectoryBox = ColObj({
  id = 'saveDirectory',
  x = love.graphics.getWidth() - 10 - inputWidth,
  y = loadedDirectoryBox.y + 35,
  w = inputWidth,
  h = 30
}, uiColWorld)

local function renderLoadDirectoryBox()
  love.graphics.setColor(1,1,1)
  local box = loadedDirectoryBox
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', box.x + 0.5, box.y + 0.5, box.w, box.h)
  guiPrint(state.loadDir or 'drag folder to load Tiled maps', box.x + 5, box.y + 6)
end

local function renderSaveDirectoryBox()
  love.graphics.setColor(1,1,1)
  local box = saveDirectoryBox
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', box.x + 0.5, box.y + 0.5, box.w, box.h)
  guiPrint(state.saveDir or 'drag folder to save to', box.x + 5, box.y + 6)
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

local function renderHoveredObjectBox()
  local o = uiState.hoveredObject
  if o then
    love.graphics.setColor(1,1,0)
    local x,y = ColObj:getPosition(o.id)
    love.graphics.rectangle('line', x + 0.5, y + 0.5, o.w, o.h)
  end
end

local function renderSelection()
  local selection = uiState.selection
  if (not selection) then
    return
  end

  local mp = uiState.mousePosition
  local mx, my = mp.x, mp.y
  Grid.forEach(selection, function(o, x, y)
    local offsetX, offsetY = (x - 1) * gridSize.w, (y - 1) * gridSize.h
    if o.type == 'mapBlock' then
      love.graphics.setColor(1,1,1,0.6)
      local canvas = layoutsCanvases[o.id]
      love.graphics.draw(canvas, mx + offsetX, my + offsetY)
    end
  end)
end

local function renderEditorModeState()
  local text = uiState.editorMode
  local w,h = getTextSize(text, getFont.debug.font)
  love.graphics.setColor(1,1,0)
  guiPrint(
    text,
    love.graphics.getWidth() - w - 10,
    love.graphics.getHeight() - h - 10
  )
end

local function placeObject()
  local canPlace = (uiState.lastPlacementGridPosition ~= uiState.placementGridPosition) or
    (uiState.lastEditorMode ~= uiState.editorMode)
  if (not canPlace) then
    return
  end

  local pgp = uiState.placementGridPosition
  local x, y = pgp.x, pgp.y
  local shouldErase = (editorModes.ERASE == uiState.editorMode)

  if shouldErase then
    local objectsGridToErase = {}
    Grid.set(objectsGridToErase, x, y, true)
    actions:send('PLACED_OBJECTS_ERASE', objectsGridToErase)
    return
  end

  local selection = uiState.selection
  if (not selection) then
    return
  end

  local nextObjectState = O.deepCopy(state.placedObjects)
  Grid.forEach(selection, function(v, localX, localY)
    local updateX, updateY = x + (localX - 1), y + (localY - 1)
    local objectToAdd = {
      id = Component.newId(),
      referenceId = v.id,
    }
    Grid.set(nextObjectState, updateX, updateY, objectToAdd)
  end)
  state:set('placedObjects', nextObjectState)
end

local function renderPlacedObjects()
  Grid.forEach(state.placedObjects, function(o, x, y)
    local tx, ty = uiState:getTranslate()
    local actualX, actualY = (x - 1) * gridSize.w + tx, (y - 1) * gridSize.h + ty
    local referenceId = o.referenceId
    local data = ColObj:get(referenceId)
    if data.type == 'mapBlock' then
      love.graphics.setColor(1,1,1)
      local canvas = layoutsCanvases[data.id]
      love.graphics.draw(canvas, actualX, actualY)
    end
  end)
end

local function renderGridSelectionState()
  love.graphics.setColor(1,1,0)
  Grid.forEach(uiState.gridSelection, function(v, x, y)
    local tx, ty = uiState:getTranslate()
    local actualX, actualY = (x - 1) * gridSize.w + tx, (y - 1) * gridSize.h + ty
    love.graphics.rectangle('line', actualX, actualY, gridSize.w, gridSize.h)
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

local handleResetSelectionKey = filterCall(function()
  actions:send('EDITOR_MODE_SET', editorModes.SELECT)
  actions:send('SELECTION_CLEAR')
end, function(ev)
  return 'escape' == ev.key
end)

local handleEraseModeKey = filterCall(function()
  actions:send('EDITOR_MODE_SET', editorModes.ERASE)
  actions:send('SELECTION_CLEAR')
end, function(ev)
  return 'e' == ev.key
end)

local handleCopyCutDeleteKey = function(ev)
  local inputState = require 'main.inputs.keyboard-manager'.state
  local keysPressed = inputState.keyboard.keysPressed
  local isCtrlKey = keysPressed.lctrl or keysPressed.rctrl
  local copyAction = 'c' == ev.key and isCtrlKey
  local cutAction = 'x' == ev.key and isCtrlKey
  local deleteAction = 'delete' == ev.key
  if copyAction or cutAction or deleteAction then
    local function convertGridSelection(gridSelection)
      local newSelection = {}
      local objectsGridToErase = {}
      local origin
      Grid.forEach(gridSelection, function(v, x, y)
        origin = origin or uiState.placementGridPosition
        local gridVal = Grid.get(state.placedObjects, x, y)
        if gridVal and (cutAction or copyAction) then
          local referenceId = gridVal.referenceId
          local objectData = ColObj:get(referenceId)
          local originOffsetX, originOffsetY = 1 - origin.x, 1 - origin.y
          Grid.set(newSelection, x + originOffsetX, y + originOffsetY, objectData)
        end
        if cutAction or deleteAction then
          Grid.set(objectsGridToErase, x, y, true)
        end
      end)
      return
        (not O.isEmpty(newSelection)) and newSelection or nil,
        (not O.isEmpty(objectsGridToErase)) and objectsGridToErase or nil
    end
    local nextSelection, objectsGridToErase = convertGridSelection(uiState.gridSelection)
    actions:send('PLACED_OBJECTS_ERASE', objectsGridToErase)
    actions:send('SELECTION_CLEAR')
    actions:send('SELECTION_SET', nextSelection)
  end
end

local handleNewLayerKey = function(ev)
  local inputState = require 'main.inputs.keyboard-manager'.state
  local keysPressed = inputState.keyboard.keysPressed
  local isShiftKey = keysPressed.lshift or keysPressed.rshift
  local isKeyComboMatch = ('n' == ev.key) and isShiftKey
  if (not isKeyComboMatch) then
    return
  end

  actions:send('LAYER_CREATE')
end

local function handleKeyPress(self, ev)
  handleResetSelectionKey(ev)
  handleEraseModeKey(ev)
  handleCopyCutDeleteKey(ev)
  handleNewLayerKey(ev)
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

    state:set('mapSize', Vec2(150, 100))

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
        uiState:set('placementGridPosition', uiState.mouseGridPosition + Vec2(1,1))

        updateUiCollisions(pos.x, pos.y)

        msgBus.send('CURSOR_SET', { type = uiState.panning and 'move' or 'default' })

        local isPlaceMode = (not uiState.hoveredObject) and (uiState.selection)
        if (isPlaceMode) then
          actions:send('EDITOR_MODE_SET', editorModes.PLACE)
        end
      end,
      onClick = function(self)
        local mode = uiState.editorMode

        local isSelectingUiObject = editorModes.SELECT == mode and
          uiState.hoveredObject and
          uiState.hoveredObject.selectable
        if isSelectingUiObject then
          actions:send('SELECTION_SET', {
            {uiState.hoveredObject}
          })
        end

        local isSelectingGridObject = editorModes.SELECT == uiState.editorMode and
          (not uiState.hoveredObject)
        if isSelectingGridObject then
          local inputState = require 'main.inputs.keyboard-manager'.state
          local isSelectionAdd = inputState.keyboard.keysPressed.lctrl or
            inputState.keyboard.keysPressed.rctrl
          local curSelection = Grid.get(
            uiState.gridSelection,
            uiState.placementGridPosition.x,
            uiState.placementGridPosition.y
          )
          local nextSelection
          if isSelectionAdd then
            nextSelection = O.clone(uiState.gridSelection)
          else
            nextSelection = {}
          end
          local nextVal = true
          if curSelection then
            nextVal = nil
          end
          Grid.set(
            nextSelection,
            uiState.placementGridPosition.x,
            uiState.placementGridPosition.y,
            nextVal
          )
          actions:send('GRID_SELECTION_SET', nextSelection)
        end
      end,
      onKeyPress = handleKeyPress,
      onKeyDown = function(self, ev)
        local inputState = require 'main.inputs.keyboard-manager'.state
        local keysPressed = inputState.keyboard.keysPressed
        local hasCtrlModifier = keysPressed.lctrl or
          keysPressed.rctrl
        if hasCtrlModifier then
          if 'z' == ev.key then
            local isRedo = keysPressed.lshift or keysPressed.rshift
            if isRedo then
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

        uiState:set('lastPlacementGridPosition', uiState.placementGridPosition)
        uiState:set('lastEditorMode', uiState.editorMode)
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
        renderPlacedObjects()
        renderLoadedLayoutObjects()
        renderLayersList()
        renderGridPosition()
        renderSelection()
        renderGridSelectionState()
        renderHoveredObjectBox()
        renderActiveTextBox()
        renderEditorModeState()

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
              local returnVal = eventHandler(c.other, ev, c) or O.EMPTY
              if returnVal.stopPropagation then
                preventBubbleEvents[msgType] = true
              end
            end
          end

          if ('MOUSE_CLICK' == msgType and not preventBubbleEvents.FOCUS) then

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
    uiState:set('textBoxCursorClock', uiState.textBoxCursorClock + dt)
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})