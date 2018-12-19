-- The main map that the player and ai interact with.

local Component = require 'modules.component'
local objectUtils = require 'utils.object-utils'
local groups = require 'components.groups'
local mapBlueprint = require 'components.map.map-blueprint'
local Map = require 'modules.map-generator.index'
local collisionGroups = require 'modules.collision-groups'
local MainMapSolidsFactory = require 'components.map.main-map-solids'
local animationFactory = require 'components.animation-factory'
local lru = require 'utils.lru'
local memoize = require'utils.memoize'
local config = require'config.config'
local Grid = require 'utils.grid'
local Background = require 'components.map.background'
local getTileValue = require 'utils.tilemap-bitmask'
local Dungeon = require 'modules.dungeon'

local generatedTileDefinitionsByMapId = {
  cache = lru.new(50),
  get = function(self, mapId)
    local tileDefs = self.cache:get(mapId)
    if (not tileDefs) then
      tileDefs = {}
      self.cache:set(mapId, tileDefs)
    end
    return tileDefs
  end
}

local Chance = require 'utils.chance'
local gridTileTypes = {
  -- walkable
  [1] = Chance({
    {
      value = 'floor-1',
      chance = 30 -- number out of 100
    },
    {
      value = 'floor-2',
      chance = 20 -- number out of 100
    },
    {
      value = 'floor-3',
      chance = 45 -- number out of 100
    },
    {
      value = 'floor-4',
      chance = 45 -- number out of 100
    },
    {
      value = 'floor-5',
      chance = 25
    },
    {
      value = 'floor-6',
      chance = 1
    },
    {
      value = 'floor-7',
      chance = 1
    },
    {
      value = 'floor-8',
      chance = 1
    },
    {
      value = 'floor-9',
      chance = 1
    }
  })
}

local defaultWallType = 'map-wall-10'
local rollWallTileType = Chance({
  {
    value = 'map-wall-10_1',
    chance = 4
  },
  {
    value = 'map-wall-10_2',
    chance = 6
  },
  {
    value = 'map-wall-10_3',
    chance = 15
  },
  {
    value = 'map-wall-10_4',
    chance = 10
  },
  {
    value = 'map-wall-10_5',
    chance = 25
  },
  {
    value = 'map-wall-10_6',
    chance = 15
  },
  {
    value = 'map-wall-10_7',
    chance = 25
  },
  {
    value = defaultWallType,
    chance = 40
  }
})

local isTileValue = function(v)
  return v == 0
end

local getTileFromTileDefinition = function(self, x, y)
  return Grid.get(self.tileDefs, x, y)
end

local function rollRandomWallType(self, grid, x, y, tileType)
  local frontFacing = 10
  local isFrontFacingType = tileType == frontFacing
  if isFrontFacingType then
    local leftTypeIsFrontFacing = getTileValue(grid, x-1, y, isTileValue) == frontFacing
    local rightTypeIsFrontFacing = getTileValue(grid, x+1, y, isTileValue) == frontFacing
    local isInBetweenFrontFacingTypes = leftTypeIsFrontFacing and rightTypeIsFrontFacing
    if isInBetweenFrontFacingTypes then
      local rolledType = rollWallTileType()
      local isRepeated = (rolledType ~= defaultWallType)
        and (
          rolledType == getTileFromTileDefinition(self, x-1, y) -- left
          or rolledType == getTileFromTileDefinition(self, x+1, y) -- right
        )
      return isRepeated and rollRandomWallType(self, grid, x, y, tileType) or rolledType
    end
  end

  return 'map-wall-'..tileType
end

local function getTileAnimationName(self, x, y, isWall)
  local grid = self.grid
  local fromCache = getTileFromTileDefinition(self, x, y)
  if fromCache then
    return fromCache
  end
  local tileType
  if isWall then
    tileType = rollRandomWallType(
      self, grid, x, y,
      getTileValue(grid, x, y, isTileValue)
    )
  else
    tileType = gridTileTypes[1]()
  end
  Grid.set(self.tileDefs, x, y, tileType)
  return tileType
end

local floorTileCrossSection = function(self, grid, v, x, y)
  local tileValueBelow = Grid.get(grid, x, y+1)
  local shouldDrawCrossSection = not tileValueBelow
  if shouldDrawCrossSection then
    local tile = animationFactory:newStaticSprite('floor-cross-section-0')
    local ox, oy = tile:getOffset()
    tile:draw(
      x * self.gridSize,
      (y + 1) * self.gridSize,
      0,
      1, 1,
      ox, oy
    )
  end
end

local animationTypes = {}

local function getAnimation(animationCache, position, name)
  animationTypes[name] = animationTypes[name] or animationFactory:new({name})
  return animationTypes[name]
end

local function addWallTileEntity(self, positionIndex, animation, x, y, opacity)
  local wallTileEntity = self.wallObjectsPool:get()
    :changeTile(animation, x, y, opacity)
end

-- Generate all collision objects ahead of time since game elements
-- like ai will need them for pathing, when they are outside of the viewport.
local function setupCollisionObjects(self, grid, gridSize)
  local cloneGrid = require 'utils.clone-grid'
  local collisionWorlds = require 'components.collision-worlds'
  local collisionGrid = cloneGrid(grid, function(v, x, y)
    if (v ~= nil) and (v ~= Map.WALKABLE) then
      -- setup collision world objects
      local gridSize = self.gridSize
      local tileX, tileY = x * gridSize, y * gridSize
      return self:addCollisionObject(
        collisionGroups.obstacle,
        tileX,
        tileY,
        gridSize,
        gridSize
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
      }):setParent(Component.get('MAIN_SCENE'))
  elseif self.wallCollisionDebug then
    self.wallCollisionDebug:delete(true)
    self.wallCollisionDebug = nil
  end
end

local blueprint = objectUtils.assign({}, mapBlueprint, {
  group = groups.firstLayer,
  class = collisionGroups.mainMap,

  init = function(self)
    self.grid = Dungeon:getData(self.mapId).grid
    self.tileDefs = generatedTileDefinitionsByMapId:get(self.mapId)
    Background.create()
    self.collisionObjectsHash = setupCollisionObjects(self, self.grid, self.gridSize)

    local cacheSize = 1200
    self.wallObjectsPool = require 'components.map.wall-objects-pool'(self.gridSize, cacheSize)

    -- IMPORTANT: the cache size should be large enough to contain all the wall tiles on the screen
    -- otherwise we will get significant cache trashing
    self.renderFloorCache = {}
    local rows, cols = #self.grid, #self.grid[1]
    local width, height = cols * self.gridSize, (rows + 3) * self.gridSize
    self.floorCanvas = love.graphics.newCanvas(width, height)
    self.wallsCanvas = love.graphics.newCanvas(width, height)
  end,

  onUpdateStart = function(self)
    -- release all all active entities (they will get used as needed)
    for _,entity in pairs(Component.groups.activeWalls.getAll()) do
      self.wallObjectsPool:release(entity)
    end
    self.drawQueue = {
      floors = {},
      walls = {}
    }
  end,

  onUpdate = function(self, value, x, y, isInViewport, dt)
    local index = Grid.getIndexByCoordinate(self.grid, x, y)
    local isEmptyTile = value == nil
    local isWall = value ~= Map.WALKABLE

    -- if its unwalkable, add a collision object and create wall tile
    if (isWall) and (not isEmptyTile) then
      renderWallCollisionDebug(self)
      local animationName = getTileAnimationName(self, x, y, isWall)
      local animation = getAnimation(self.animationCache, index, animationName)
        :update(dt)
      local tileAbove = Grid.get(self.grid, x, y - 1)
      addWallTileEntity(self, index,
        animation,
        x,
        y,
        tileAbove == Map.WALKABLE and 0.75 or 1
      )
    end

    -- floor tiles
    if self.renderFloorCache[index] then
      return
    else
      self.renderFloorCache[index] = true
    end

    --[[
      We must render walls onto a separate layer to get the correct
      draw ordering. We also must render these before the actual walls
      since the actual walls have some transparency which will otherwise reveal the game's
      background color underneath.
    ]]
    local canvas = isWall and self.wallsCanvas or self.floorCanvas
    local drawQueue = self.drawQueue[isWall and 'walls' or 'floors']
    local function drawFn()
      love.graphics.setColor(1,1,1)
      floorTileCrossSection(self, self.grid, value, x, y)
      local animationName = getTileAnimationName(self, x, y, isWall)
      local animation = getAnimation(self.animationCache, index, animationName)
        :update(dt)
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
    table.insert(drawQueue, drawFn)
  end,

  onUpdateEnd = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self.floorCanvas)
    for i=1, #self.drawQueue.floors do
      local callback = self.drawQueue.floors[i]
      callback()
    end

    love.graphics.setCanvas(self.wallsCanvas)
    for i=1, #self.drawQueue.walls do
      local callback = self.drawQueue.walls[i]
      callback()
    end

    love.graphics.setCanvas()
    love.graphics.pop()
  end,

  renderEnd = function(self)
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.floorCanvas)
    love.graphics.draw(self.wallsCanvas)
  end,

  serialize = function(self)
    return self.grid
  end,

  drawOrder = function()
    return 2
  end
})

return Component.createFactory(blueprint)