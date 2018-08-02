local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local mapBlueprint = require 'components.map.map-blueprint'
local animationFactory = require 'components.animation-factory'
local lru = require 'utils.lru'

local function getAnimation(animationCache, position, name)
  local fromCache = animationCache:get(position)

  if not fromCache then
    animationCache:set(position, animationFactory:new({name}))
    return animationCache:get(position)
  end

  return fromCache
end

local function getIndexByCoordinate(x, y, maxCols)
  return (y * maxCols) + x
end

-- coordinates are in pixels
local function addCollisionObject(self, animation, positionIndex, sx, sy)
  local fromCache = self.collisionObjectCache:get(positionIndex)
  if fromCache then
    return fromCache
  end
  local w = animation:getSourceSize()
  local ox, oy = animation:getSourceOffset()
  local object = collisionObject:new(
    'obstacle',
    sx, sy, w, self.gridSize, ox, oy - (self.gridSize / 2)
  ):addToWorld(collisionWorlds.map)
  self.collisionObjectCache:set(positionIndex, object)
  return object
end

local function removeCollisionObject(self, positionIndex)
  local colObj = self.collisionObjectCache:get(positionIndex)
  if colObj then
    colObj:removeFromWorld(collisionWorlds.map)
  end
end

local blueprint = objectUtils.assign({}, mapBlueprint, {
  tileRenderDefinition = {},

  init = function(self)
    self.animationCache = lru.new(1400)

    -- remove collision objects when the lru cache automatically prunes
    local collisionPruneCallback = function(key)
      removeCollisionObject(self, key)
    end
    self.collisionObjectCache = lru.new(600, nil, collisionPruneCallback)
  end,

  onUpdate = function(self, value, x, y, originX, originY, isInViewport, dt)
    local maxCols = #self.grid[1]
    local index = getIndexByCoordinate(x, y, maxCols)
    local animationName = self.tileRenderDefinition[y][x]
    local animation = getAnimation(self.animationCache, index, animationName)
      :update(dt)
    -- if its unwalkable, add a collision object
    if value ~= self.walkable then
      addCollisionObject(self, animation, index, x * self.gridSize, y * self.gridSize)
    else
      removeCollisionObject(self, index)
    end
  end,

  render = function(self, value, x, y, originX, originY)
    local maxCols = #self.grid[1]
    local index = getIndexByCoordinate(x, y, maxCols)
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
})

return groups.all.createFactory(blueprint)