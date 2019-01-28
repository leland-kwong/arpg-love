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

local gridSize = 32
local colWorld = bump.newWorld(gridSize)

local uiCollisions = {}
local stateMt = {
  _onChange = function()
  end,
  set = function(self, k, v)
    local currentVal = self[k]
    self[k] = v
    self._onChange(self, k, v, currentVal)
  end,
  onChange = function(self, callback)
    self._onChange = callback
  end
}
stateMt.__index = stateMt
local state = setmetatable({
  loadDir = nil,
  saveDir = nil,
  fileStateContext = nil,
  mousePosition = Vec2(0, 0),
  mouseGridPosition = Vec2(0, 0),
  objects = {},
  layouts = {}
}, stateMt)

-- Lua implementation of PHP scandir function
function loadLayouts(directory)
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

state:onChange(function(self, k, val, prevVal)
  local isNewLoadDir = k == 'loadDir' and val ~= prevVal
  if isNewLoadDir then
    state:set('layouts', loadLayouts(val))
  end
end)

local function renderMousePosition(self)
  love.graphics.setColor(0,0.5,1)
  local mgp = state.mousePosition
  love.graphics.rectangle('line', mgp.x, mgp.y, gridSize, gridSize)
end

local function iterateListAsGrid(list, numCols, callback)
  for i=1, #list do
    local val = list[i]
    local x, y = Grid.getCoordinateByIndex(list, i, numCols)
    callback(val, x, y)
  end
end

local uiEvents = {
  MOUSE_CLICKED = function(ev)
    print(ev)
  end
}

local tileRenderer = {
  [1] = function(x, y, w, h)
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.rectangle('fill', x, y, w, h)
  end,
  [12] = function(x, y, w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('fill', x, y, w, h)
  end
}

local layoutsCanvas = love.graphics.newCanvas(4096, 4096)
local renderLayouts = memoize(function (layouts, groupOrigin)
  local oBlendMode = love.graphics.getBlendMode()
  love.graphics.setBlendMode('alpha', 'premultiplied')
  love.graphics.setCanvas(layoutsCanvas)
  love.graphics.clear()
  love.graphics.setColor(1,1,1)

  local tileRenderSize = 1
  local layouts = state.layouts
  local offsetY = 0
  for i=1, #layouts do
    local origin = {
      x = groupOrigin.x,
      y = groupOrigin.y + offsetY
    }
    local l = layouts[i]

    love.graphics.print(l.file, origin.x, origin.y - 20)

    local groundLayer = F.find(l.data.layers, function(l)
      return l.name == 'ground'
    end)
    if groundLayer then
      iterateListAsGrid(groundLayer.data, 60, function(v, x, y)
        if tileRenderer[v] then
          tileRenderer[v](origin.x + x * tileRenderSize, origin.y + y * tileRenderSize, tileRenderSize, tileRenderSize)
        end
      end)
    end

    local wallLayer = F.find(l.data.layers, function(l)
      return l.name == 'walls'
    end)
    if wallLayer then
      iterateListAsGrid(wallLayer.data, 60, function(v, x, y)
        if tileRenderer[v] then
          tileRenderer[v](origin.x + x * tileRenderSize, origin.y + y * tileRenderSize, tileRenderSize, tileRenderSize)
        end
      end)
    end

    offsetY = offsetY + l.data.height + 20
  end

  love.graphics.setCanvas()
  love.graphics.setBlendMode(oBlendMode)
end)

local loadedDirectoryBox = {
  id = 'loadedDirectory',
  x = 10,
  y = 100,
  w = 500,
  h = 30
}

colWorld:add(
  loadedDirectoryBox,
  loadedDirectoryBox.x,
  loadedDirectoryBox.y,
  loadedDirectoryBox.w,
  loadedDirectoryBox.h
)

local saveDirectoryBox = {
  id = 'saveDirectory',
  x = 10,
  y = 135,
  w = 500,
  h = 30
}

colWorld:add(
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
  local isHovered = F.find(uiCollisions, function(c)
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
  guiPrint(state.loadDir or 'drag folder to load tiled maps', box.x + 3, box.y + 5)
end

local function renderSaveDirectoryBox()
  local isHovered = F.find(uiCollisions, function(c)
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
  local context = F.find(uiCollisions, function(c)
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
    state:set(fileStateContext, dir)
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

local layoutGroupOrigin = {
  x = 10,
  y = 200
}

Component.create({
  id = 'LayoutEditor',
  group = 'gui',

  init = function(self)
    local mouseCollision = {}
    colWorld:add(mouseCollision, 0, 0, 1, 1)

    Gui.create({
      x = 0,
      y = 0,
      inputContext = 'editorBase',
      scale = 1,
      onPointerMove = function(self, ev)
        local pos = getCursorPos()
        local gridX, gridY = Position.pixelsToGridUnits(pos.x, pos.y, gridSize)
        local posX, posY = gridX * gridSize, gridY * gridSize
        state:set('mousePosition', Vec2(posX, posY))
        state:set('mouseGridPosition', Vec2(gridX, gridY))

        local _, _, cols, len = colWorld:move(mouseCollision, pos.x, pos.y, function()
          return 'cross'
        end)
        uiCollisions = cols

        msgBus.send('CURSOR_SET', { type = 'default' })
      end,
      onClick = function(self)
        -- place a layout down
      end,
      onUpdate = function(self, dt)
        self.w, self.h = love.graphics.getWidth(),
          love.graphics.getHeight()
      end,
      render = function(self)
        love.graphics.push()
        love.graphics.origin()

        renderMousePosition(self)
        renderLayouts(state.layouts, layoutGroupOrigin)
        love.graphics.setColor(1,1,1)
        love.graphics.draw(layoutsCanvas)

        renderGuiElements(self)

        love.graphics.pop()
      end
    }):setParent(self)

    self.listeners = {
      msgBus.on('*', function(ev, msgType)
        local eventHandler = uiEvents[msgType]
        if eventHandler then
          for i=1, #uiCollisions do
            local c = uiCollisions[i]
            eventHandler(c)
          end
        end
      end)
    }
  end,
})