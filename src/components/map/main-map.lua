local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local mapBlueprint = require 'components.map.map-blueprint'
local animationFactory = require 'components.animation-factory'
local lru = require 'utils.lru'

local function getAnimation(animationCache, position, name)
  local fromCache = animationCache:get(position)

  if not fromCache then
    animationCache:set(position, animationFactory.create({name}))
    return animationCache:get(position)
  end

  return fromCache
end

local function getIndexByCoordinate(x, y, maxCols)
  return (y * maxCols) + x
end

local blueprint = objectUtils.assign({}, mapBlueprint, {
  tileRenderDefinition = {},

  init = function(self)
    self.animationCache = lru.new(1400)
  end,

  onUpdate = function(self, value, x, y, originX, originY, isInViewport, dt)
    local maxCols = #self.grid[1]
    local index = getIndexByCoordinate(x, y, maxCols)
    local animationName = self.tileRenderDefinition[y][x]
    getAnimation(self.animationCache, index, animationName):update(dt)
  end,

  render = function(self, value, x, y, originX, originY)
    local maxCols = #self.grid[1]
    local index = getIndexByCoordinate(x, y, maxCols)
    local animationName = self.tileRenderDefinition[y][x]
    local animation = getAnimation(self.animationCache, index, animationName)
    local ox, oy = animation:getOffset()
    local tileX, tileY = x * self.gridSize, y * self.gridSize
    love.graphics.draw(
      animationFactory.spriteAtlas,
      animation.sprite,
      tileX,
      tileY,
      0,
      1,
      1,
      ox,
      oy - self.gridSize
    )
  end
})

return groups.all.createFactory(blueprint)