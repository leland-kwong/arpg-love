local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local mapBlueprint = require 'components.map.map-blueprint'
local config = require 'config'

local COLOR_TILE_OUT_OF_VIEW = {1,1,1,0.3}
local COLOR_TILE_IN_VIEW = {1,1,1,1}
local FILL_STYLE = 'fill'
local floor = math.floor
local minimapTileRenderers = {
  -- obstacle
  [0] = function(self, x, y, originX, originY, isInViewport)
    local actualX = x - originX
    local actualY = y - originY

    local _r, _g, _b, _a = love.graphics.getColor()
    love.graphics.setColor(isInViewport and COLOR_TILE_IN_VIEW or COLOR_TILE_OUT_OF_VIEW)

    local rectSize = 1
    local x = (self.x * rectSize) + actualX
    local y = (self.y * rectSize) + actualY
    love.graphics.rectangle(
      FILL_STYLE,
      x, y, rectSize, rectSize
    )

    love.graphics.setColor(_r, _g, _b, _a)
  end,
  -- walkable
  [1] = function(x, y)
  end,
}

local minimapCanvas = love.graphics.newCanvas()
-- minimap
local blueprint = objectUtils.assign({}, mapBlueprint, {
  x = 100,
  y = 100,
  offset = 10,
  renderStart = function(self)
    love.graphics.push()
    love.graphics.setCanvas(minimapCanvas)
    love.graphics.clear(0,0,0,0)
  end,

  render = function(self, value, _x, _y, originX, originY, isInViewport)
    minimapTileRenderers[value](self, _x, _y, originX, originY, isInViewport)
  end,

  renderEnd = function(self)
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1,1)
    love.graphics.scale(self.scale)
    love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(minimapCanvas)
    love.graphics.setBlendMode('alpha')
    love.graphics.pop()
  end
})

return groups.hud.createFactory(blueprint)