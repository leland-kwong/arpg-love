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
local config = require'config.config'

local animationTypes = {}

local function getAnimation(animationCache, position, name)
  animationTypes[name] = animationTypes[name] or animationFactory:new({name})
  return animationTypes[name]
end

local function addWallTileEntity(self, positionIndex, animation, x, y, opacity)
  local wallTileEntity = self.wallObjectsPool:get()
    :changeTile(animation, x, y, opacity)
    :setParent(self)
  self.wallTileCache:set(positionIndex, wallTileEntity)
end

local function getTile(grid, x, y)
  return grid[y] and grid[y][x]
end

-- Generate all collision objects ahead of time since game elements
-- like ai will need them for pathing, when they are outside of the viewport.
local function setupCollisionObjects(self, grid, gridSize)
  local cloneGrid = require 'utils.clone-grid'
  local collisionWorlds = require 'components.collision-worlds'
  local collisionGrid = cloneGrid(grid, function(v, x, y)
    if v ~= Map.WALKABLE then
      -- setup collision world objects
      local gridSize = self.gridSize
      local tileX, tileY = x * gridSize, y * gridSize
      return self:addCollisionObject(
        'obstacle',
        tileX, tileY, gridSize, gridSize, gridSize/2 - 1, gridSize
      ):addToWorld(collisionWorlds.map)
    end
  end)
  return collisionGrid
end

local function renderWallCollisionDebug(self)
  local WallCollisionDebug = require 'components.map.wall-collision-debug'
  if config.collisionDebug then
    self.wallCollisionDebug = self.wallCollisionDebug or
      WallCollisionDebug.create({
        grid = self.grid,
        collisionObjectsHash = self.collisionObjectsHash,
        camera = self.camera
      }):setParent(self)
  elseif self.wallCollisionDebug then
    self.wallCollisionDebug:delete(true)
    self.wallCollisionDebug = nil
  end
end

local blueprint = objectUtils.assign({}, mapBlueprint, {
  group = groups.all,
  tileRenderDefinition = {},

  init = function(self)
    self.collisionObjectsHash = setupCollisionObjects(self, self.grid, self.gridSize)

    local cacheSize = 600
    self.wallObjectsPool = require 'components.map.wall-objects-pool'(self.gridSize, cacheSize)

    local function wallTilePruneCallback(key, entity)
      self.wallObjectsPool:release(entity)
    end
    -- IMPORTANT: the cache size should be large enough to contain all the wall tiles on the screen
    -- otherwise we will get significant cache trashing
    self.wallTileCache = lru.new(cacheSize, nil, wallTilePruneCallback)
    self.renderFloorCache = {}
    local rows, cols = #self.grid, #self.grid[1]
    self.floorCanvas = love.graphics.newCanvas(cols * self.gridSize, rows * self.gridSize)
  end,

  onUpdate = function(self, value, x, y, originX, originY, isInViewport, dt)
    renderWallCollisionDebug(self)

    -- if its unwalkable, add a collision object and create wall tile
    if value ~= Map.WALKABLE then
      local index = GetIndexByCoordinate(self.grid)(x, y)
      local animationName = self.tileRenderDefinition[y][x]
      local animation = getAnimation(self.animationCache, index, animationName)
        :update(dt)
      local cached = self.wallTileCache:get(index)
      if (not cached) then
        local tileAbove = getTile(self.grid, x, y - 1)
        addWallTileEntity(self, index,
          animation,
          x,
          y,
          tileAbove == Map.WALKABLE and 0.75 or 1
        )
      end
    end
  end,

  renderStart = function(self)
    love.graphics.setCanvas(self.floorCanvas)
    love.graphics.push()
    love.graphics.origin()
  end,

  render = function(self, value, x, y, originX, originY)
    if value == Map.WALKABLE then
      local index = GetIndexByCoordinate(self.grid)(x, y)
      if self.renderFloorCache[index] then
        return
      else
        self.renderFloorCache[index] = true
      end

      local animationName = self.tileRenderDefinition[y][x]
      local animation = getAnimation(self.animationCache, index, animationName)
      local ox, oy = animation:getOffset()
      local tileX, tileY = x * self.gridSize, y * self.gridSize

      love.graphics.setColor(1,1,1)
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

  renderEnd = function(self)
    love.graphics.pop()
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.floorCanvas)
  end
})

return Component.createFactory(blueprint)