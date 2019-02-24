local Component = require 'modules.component'
local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local MapBlueprint = require 'components.map.map-blueprint'
local Map = require 'modules.map-generator.index'
local config = require 'config.config'

return Component.createFactory(
  objectUtils.assign({}, MapBlueprint, {
    group = groups.all,
    render = function(self, value, x, y, originX, originY)
      if config.collisionDebug and (not Map.WALKABLE(value)) then
        local colObj = self.collisionObjectsHash[y][x]
        if colObj then
          love.graphics.setColor(1,1,0,0.2)
          local renderX, renderY = colObj:getPositionWithOffset()
          love.graphics.rectangle('fill', renderX, renderY, colObj.w, colObj.h)
        end
      end
    end,
    drawOrder = function(self)
      return math.pow(10, 10)
    end
  })
)