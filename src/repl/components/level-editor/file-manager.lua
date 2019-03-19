return function(states, guiPrint, ColObj, uiColWorld)
  local inputWidth = 500
  local state = states.state
  local uiState = states.uiState

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

  return {
    render = function()
      renderLoadDirectoryBox()
      renderSaveDirectoryBox()
    end
  }
end