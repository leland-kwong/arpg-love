local getFont = require 'components.font'

return function(states, ColObj, uiColWorld, TextBox)
  local state = states.state

  local layersListCanvas = love.graphics.newCanvas(400, 1000)

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

      local layerObj = TextBox({
        id = l.id,
        x = layersContainerBox.x,
        y = layersContainerBox.y + offsetY,
        w = layersContainerBox.w,
        h = 20,
        text = l.label
      }, uiColWorld)

      love.graphics.setFont(getFont.debug.font)
      love.graphics.print(l.label, 0, offsetY)

      offsetY = offsetY + layerObj.h
    end

    love.graphics.pop()
    love.graphics.setCanvas()
  end

  local function renderLayersList()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(layersListCanvas, layersContainerBox.x, layersContainerBox.y)
  end

  return {
    update = updateLayersListUi,
    render = renderLayersList
  }
end