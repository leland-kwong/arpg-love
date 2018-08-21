-- The main map that the player and ai interact with.

local Component = require 'modules.component'
local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local mapBlueprint = require 'components.map.map-blueprint'
local Map = require 'modules.map-generator.index'
local MainMapSolidsFactory = require 'components.map.main-map-solids'
local animationFactory = require 'components.animation-factory'
local lru = require 'utils.lru'
local memoize = require'utils.memoize'
local GetIndexByCoordinate = memoize(require 'utils.get-index-by-coordinate')
local config = require'config'

local animationTypes = {}

local function getAnimation(animationCache, position, name)
  animationTypes[name] = animationTypes[name] or animationFactory:new({name})
  return animationTypes[name]
end

local function getWallEntity(self, positionIndex)
  return self.wallTileCache:get(positionIndex)
end

local function addWallTileEntity(self, positionIndex, entityProps)
  local wallTileEntity = MainMapSolidsFactory.create(entityProps):setParent(self)
  self.wallTileCache:set(positionIndex, wallTileEntity)
end

local blueprint = objectUtils.assign({}, mapBlueprint, {
  group = groups.all,
  tileRenderDefinition = {},

  init = function(self)
    local function wallTilePruneCallback(key, entity)
      entity:delete()
    end
    self.wallTileCache = lru.new(400, nil, wallTilePruneCallback)
    self.renderFloorCache = {}
  end,

  onUpdate = function(self, value, x, y, originX, originY, isInViewport, dt)
    -- if its unwalkable, add a collision object and create wall tile
    if value ~= Map.WALKABLE then
      local index = GetIndexByCoordinate(self.grid)(x, y)
      local animationName = self.tileRenderDefinition[y][x]
      local animation = getAnimation(self.animationCache, index, animationName)
        :update(dt)
      local tileX, tileY = x * self.gridSize, y * self.gridSize
      local ox, oy = animation:getOffset()
      local cached = getWallEntity(self, index)
      if not cached then
        addWallTileEntity(self, index, {
          animation = animation,
          x = tileX,
          y = tileY,
          ox = ox,
          oy = oy,
          gridSize = self.gridSize
        })
      end
    end
  end,

  render = function(self, value, x, y, originX, originY)
    if value == Map.WALKABLE then
      local index = GetIndexByCoordinate(self.grid)(x, y)
      local animationName = self.tileRenderDefinition[y][x]
      local animation = getAnimation(self.animationCache, index, animationName)
      local ox, oy = animation:getOffset()
      local tileX, tileY = x * self.gridSize, y * self.gridSize

      love.graphics.draw(
        animation.atlas,
        animation.sprite,
        tileX,
        tileY,
        0,
        1,
        1,
        ox,
        oy
      )
    end
  end,
})

return Component.createFactory(blueprint)