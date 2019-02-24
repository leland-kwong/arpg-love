local memoize = require 'utils.memoize'
local F = require 'utils.functional'
local Grid = require 'utils.grid'

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

return function(states, ColObj, uiColWorld, layoutsCanvases, actions, editorModes, guiPrint)
  local uiState = states.uiState

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

  local updateLayouts = memoize(function (directoryToLoad, groupOrigin)
    local layouts = loadLayouts(directoryToLoad)
    uiState:set('loadedLayouts', layouts)

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

  return {
    update = updateLayouts,
    render = renderLoadedLayoutObjects
  }
end