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

local uiColWorld = bump.newWorld(32)
local gridSize = {
  w = 20,
  h = 20
}
local layoutsCanvases = {}

local function guiPrint(text, x, y)
  love.graphics.setFont(getFont.debug.font)
  love.graphics.print(text, x, y)
end

local states = dynamicRequire 'repl.components.level-editor.states'
local ColObj = dynamicRequire 'repl.components.level-editor.libs.collision'
local constants = dynamicRequire 'repl.components.level-editor.constants'
local filterCall = require 'utils.filter-call'
local getTextSize = require 'repl.components.level-editor.libs.get-text-size'
local getCursorPos = require 'repl.components.level-editor.libs.get-cursor-position'
local TextBox = dynamicRequire 'repl.components.level-editor.text-box'(states, ColObj)
local actions = dynamicRequire 'repl.components.level-editor.actions'(states, constants)
local handleKeyPress = dynamicRequire 'repl.components.level-editor.hotkeys'(actions, constants, states, ColObj)
local guiEventsHandler = dynamicRequire 'repl.components.level-editor.gui-events-handler'
local layersList = dynamicRequire 'repl.components.level-editor.layers-list'(states, ColObj, uiColWorld, TextBox)
local fileManager = dynamicRequire 'repl.components.level-editor.file-manager'(states, guiPrint, ColObj, uiColWorld)
local layoutList = dynamicRequire 'repl.components.level-editor.selectable-layout-list'(
  states,
  ColObj,
  uiColWorld,
  layoutsCanvases,
  actions,
  constants.editorModes,
  guiPrint
)

local function ObjectEditor(origin, states, gridSize, ColObj, uiColWorld)
  local memoizeOne = require 'utils.memoize-one'
  local Grid = require 'utils.grid'

  local uiState = states.uiState
  local objectsSelectedCanvas = love.graphics.newCanvas(4096, 4096)
  local objectsCanvas = love.graphics.newCanvas(4096, 4096)
  local offsetY = 25
  local padding = 10

  local shapeTypeOptions = {
    ColObj({
      id = 'shapeTypePoint',
      x = origin.x + padding,
      y = origin.y + padding + offsetY,
      w = 30,
      h = 30,
      type = 'gridObject',
      selectable = true
    }, uiColWorld)
  }

  local indexOffset = 1
  local shapeRenderers = {
    gridObject = function(x, y)
      love.graphics.setColor(0,1,1)
      local radius = 4
      love.graphics.circle('fill', x, y, 4)
    end
  }

  local updatePlacedObjectsMemoized = memoizeOne(function(placedObjects)
    love.graphics.setCanvas(objectsCanvas)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.clear()
    local oBlendMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode('alpha', 'premultiplied')

    Grid.forEach(placedObjects, function(o, x, y)
      local referenceId = o.referenceId
      local data = ColObj:get(referenceId)
      if data.type == 'gridObject' then
        shapeRenderers[data.type](x, y)
      end
    end)

    love.graphics.setCanvas()
    love.graphics.pop()
    love.graphics.setBlendMode(oBlendMode)
  end)
  local updateSelectionObjectsMemoized = memoizeOne(function(selection)
    if (not selection) then
      return
    end

    love.graphics.setCanvas(objectsSelectedCanvas)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.clear()
    local oBlendMode = love.graphics.getBlendMode()
    love.graphics.setBlendMode('alpha', 'premultiplied')

    Grid.forEach(selection, function(o, x, y)
      if o.type == 'gridObject' then
        shapeRenderers[o.type](x, y)
      end
    end)

    love.graphics.setCanvas()
    love.graphics.pop()
    love.graphics.setBlendMode(oBlendMode)
  end)

  local update = function()
    updatePlacedObjectsMemoized(states.state.placedObjects)
    updateSelectionObjectsMemoized(uiState.selection)
  end

  local function renderUiPanel()
    local title = 'Objects'
    love.graphics.print(title, origin.x + padding, origin.y + padding)

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.rectangle('line', origin.x + 0.5, origin.y + 0.5, 200, 34 + offsetY + (padding * 2))
    for i=1, #shapeTypeOptions do
      local box = shapeTypeOptions[i]
      love.graphics.setColor(0,1,1)
      love.graphics.circle('line', box.x + 0.5 + box.w/2, box.y + 0.5 + box.h/2, box.w/2)
    end
  end

  local function render(item)
    local tx, ty = uiState:getTranslate()
    love.graphics.draw(objectsCanvas, tx, ty)
    if uiState.selection then
      local mp = uiState.mousePosition
      local mx, my = mp.x, mp.y
      love.graphics.draw(objectsSelectedCanvas, mx, my)
    end
  end

  return {
    update = update,
    renderUiPanel = renderUiPanel,
    render = render
  }
end

local objectEditor = ObjectEditor(
  Vec2(150, 10),
  states,
  gridSize,
  ColObj,
  uiColWorld
)

local state = states.state
local uiState = states.uiState

local editorModes = constants.editorModes

local gridCanvas = love.graphics.newCanvas(4096, 4096)

local function panTo(x, y)
  local tx = uiState.translate
  tx.x, tx.y = x, y
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

state:onChange(function(self, k, val, prevVal)
  local isNewVal = val ~= prevVal

  local isNewLoadDir = k == 'loadDir' and isNewVal
  if isNewLoadDir then
    layoutList.update(val,  {
      x = 10,
      y = 10
    })
  end

  local layersListChanged = k == 'layersList' and isNewVal
  if layersListChanged then
    layersList.update(val)
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
    local offsetX, offsetY = (x), (y)
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

  local pp = uiState.placementPosition
  local x, y = pp.x, pp.y
  local shouldErase = (editorModes.ERASE == uiState.editorMode)

  if shouldErase then
    local objectsGridToErase = {}
    Grid.set(objectsGridToErase, x, y, true)
    actions:send('PLACED_OBJECTS_ERASE', objectsGridToErase)
    return
  end

  actions:send('PLACED_OBJECTS_UPDATE', {
    x = x,
    y = y,
    selection = uiState.selection
  })
end

local function renderPlacedObjects()
  Grid.forEach(state.placedObjects, function(o, x, y)
    local tx, ty = uiState:getTranslate()
    local actualX, actualY = (x) + tx, (y) + ty
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
    local actualX, actualY = (x) + tx, (y) + ty
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
        uiState:set('placementPosition', Vec2(uiState.mouseGridPosition.x * gridSize.w, uiState.mouseGridPosition.y * gridSize.h))

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
            uiState.placementPosition.x,
            uiState.placementPosition.y
          )
          local nextSelection
          if isSelectionAdd then
            nextSelection = Grid.clone(uiState.gridSelection)
          else
            nextSelection = {}
          end
          local nextVal = true
          if curSelection then
            nextVal = nil
          end
          Grid.set(
            nextSelection,
            uiState.placementPosition.x,
            uiState.placementPosition.y,
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

        fileManager.render()
        renderPlacedObjects()
        layoutList.render()
        layersList.render()
        objectEditor.renderUiPanel()
        objectEditor.render()
        renderGridPosition()
        renderSelection()
        renderGridSelectionState()
        renderHoveredObjectBox()
        TextBox.renderActiveTextBox()
        renderEditorModeState()

        love.graphics.pop()
      end
    }):setParent(self)

    self.listeners = {
      guiEventsHandler(states, actions, editorModes, ColObj, msgBus, O),
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
    if (not ColObj:getFocused()) then
      uiState:set('panning', love.keyboard.isDown('space'))
    end
    uiState:set('textBoxCursorClock', uiState.textBoxCursorClock + dt)

    local pos = getCursorPos()
    updateUiCollisions(pos.x, pos.y)
    objectEditor.update()
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})