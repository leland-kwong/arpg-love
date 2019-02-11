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
local bitmaskTileValue = require 'utils.tilemap-bitmask'
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

local defaultWallType = 'map-wall-10_1'
local rollWallTileType = Chance({
  {
    value = 'map-wall-10_2',
    chance = 4
  },
  {
    value = 'map-wall-10_3',
    chance = 15
  },
  {
    value = 'map-wall-10_4',
    chance = 4
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
    value = 'map-wall-10_8',
    chance = 4
  },
  {
    value = defaultWallType,
    chance = 37
  }
})

local isTileValue = function(v)
  return not Dungeon.isEmptyTile(v) and (not v.walkable)
end

local getTileFromTileDefinition = function(self, x, y)
  return Grid.get(self.tileDefs, x, y)
end

local frontFacingTileTypes = {
  [10] = true,
  [11] = true
}

local function rollRandomWallType(self, grid, x, y, tileType)
  local isFrontFacingType = frontFacingTileTypes[tileType]
  local detailTile
  if isFrontFacingType then
    detailTile = 'map-wall-10_1'

    local leftType = bitmaskTileValue(grid, x-1, y, isTileValue)
    local leftTypeIsFrontFacing = frontFacingTileTypes[leftType]
    local rightType = bitmaskTileValue(grid, x+1, y, isTileValue)
    local rightTypeIsFrontFacing = frontFacingTileTypes[rightType]
    local isInBetweenFrontFacingTypes = leftTypeIsFrontFacing and rightTypeIsFrontFacing
    if isInBetweenFrontFacingTypes then
      local rolledType = rollWallTileType()
      local isRepeated = (rolledType ~= defaultWallType)
        and (
          rolledType == getTileFromTileDefinition(self, x-1, y) -- left
          or rolledType == getTileFromTileDefinition(self, x+1, y) -- right
        )
      detailTile = isRepeated and rollRandomWallType(self, grid, x, y, tileType) or rolledType
    end
  end

  return {
    'map-wall-'..tileType,
    detailTile
  }
end

local function getTileAnimationName(self, x, y, isWall)
  local grid = self.grid
  local fromCache = getTileFromTileDefinition(self, x, y)
  if fromCache then
    return fromCache
  end
  local tileTypes
  if isWall then
    tileTypes = rollRandomWallType(
      self, grid, x, y,
      bitmaskTileValue(grid, x, y, isTileValue)
    )
  else
    tileTypes = {gridTileTypes[1]()}
  end
  Grid.set(self.tileDefs, x, y, tileTypes)
  return tileTypes
end

local floorTileCrossSection = function(self, grid, animationName, x, y)
  local tile = animationFactory:newStaticSprite(animationName)
  local ox, oy = tile:getOffset()
  tile:draw(
    x * self.gridSize,
    (y + 1) * self.gridSize,
    0,
    1, 1,
    ox, oy
  )
end

local animationTypes = {}

local function getAnimation(animationCache, position, name)
  animationTypes[name] = animationTypes[name] or animationFactory:new({name})
  return animationTypes[name]
end

local function addWallTileEntity(self, positionIndex, animation, x, y, opacity, layer)
  local wallTileEntity = self.wallObjectsPool:get()
    :changeTile(animation, x, y, opacity, layer)
end

local function neighborCheckCallback(hasNeighbor, cellValue)
  return hasNeighbor or not Dungeon.isEmptyTile(cellValue)
end

-- Generate all collision objects ahead of time since game elements
-- like ai will need them for pathing, when they are outside of the viewport.
local function setupCollisionObjects(self, grid, gridSize)
  local cloneGrid = require 'utils.clone-grid'
  local collisionWorlds = require 'components.collision-worlds'
  local collisionGrid = cloneGrid(grid, function(v, x, y)
    if (not Map.WALKABLE(v)) then
      local isEmptyTile = Dungeon.isEmptyTile(v)
      -- ignore any holes in the map
      if isEmptyTile then
        local hasNeighbor = Grid.walkNeighbors(grid, x, y, neighborCheckCallback, false, true)
        if (not hasNeighbor) then
          return
        end
      end

      -- setup collision world objects
      local gridSize = self.gridSize
      local tileX, tileY = x * gridSize, y * gridSize
      return self:addCollisionObject(
        'obstacle',
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

  isEmptyTile = Dungeon.isEmptyTile,

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
    self.crossSectionCanvas = love.graphics.newCanvas(width, height)
    self.floorCanvas = love.graphics.newCanvas(width, height)
    self.wallsCanvas = love.graphics.newCanvas(width, height)
    self.shadowsCanvas = love.graphics.newCanvas(width, height)
  end,

  onUpdateStart = function(self)
    -- release all active entities (they will get used as needed)
    for _,entity in pairs(Component.groups.activeWalls.getAll()) do
      self.wallObjectsPool:release(entity)
    end
    self.drawQueue = {
      floors = {},
      walls = {},
      shadows = {},
      crossSections = {}
    }
  end,

  onUpdate = function(self, value, x, y, isInViewport, dt)
    local index = Grid.getIndexByCoordinate(self.grid, x, y)
    local isEmptyTile = Dungeon.isEmptyTile(value)
    local isWall = not Map.WALKABLE(value)

    -- if its unwalkable, add a collision object and create wall tile
    if (isWall) and (not isEmptyTile) then
      renderWallCollisionDebug(self)
      local animationsList = value.animations or
        getTileAnimationName(self, x, y, isWall)
      for i=1, #animationsList do
        local animationName = animationsList[i]
        local animation = getAnimation(self.animationCache, index, animationName)
          :update(dt)
        local tileAbove = Grid.get(self.grid, x, y - 1)
        addWallTileEntity(self, index,
          animation,
          x,
          y,
          Map.WALKABLE(tileAbove) and 0.75 or 1,
          (i - 1)
        )
      end
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
      if value.color then
        love.graphics.setColor(value.color)
      else
        love.graphics.setColor(1,1,1)
      end
      local animationsList = value.animations or
        getTileAnimationName(self, x, y, isWall)
      for i=1, #animationsList do
        local animationName = animationsList[i]
        local animation = getAnimation(self.animationCache, index, animationName)
          :update(dt)
        local ox, oy = animation:getOffset()
        local tileX, tileY = value.x or (x * self.gridSize),
          value.y or (y * self.gridSize)

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
    end
    table.insert(drawQueue, drawFn)

    if value.shadow then
      local function drawShadow()
        local s = value.shadow
        love.graphics.setColor(s.color)
        animationFactory:newStaticSprite(s.sprite)
          :draw(s.x, s.y, nil, s.sx, s.sy)
      end
      table.insert(self.drawQueue.shadows, drawShadow)
    end

    if value.crossSection then
      local tileValueBelow = Grid.get(self.grid, x, y+1)
      local shouldDrawCrossSection = Dungeon.isEmptyTile(tileValueBelow)
      if shouldDrawCrossSection then
        table.insert(self.drawQueue.crossSections, function()
          love.graphics.setColor(1,1,1)
          floorTileCrossSection(self, self.grid, value.crossSection, x, y)
        end)
      end
    end
  end,

  onUpdateEnd = function(self)
    love.graphics.push()
    love.graphics.origin()

    love.graphics.setCanvas(self.crossSectionCanvas)
    for i=1, #self.drawQueue.crossSections do
      local callback = self.drawQueue.crossSections[i]
      callback()
    end

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

    love.graphics.setCanvas(self.shadowsCanvas)
    for i=1, #self.drawQueue.shadows do
      local callback = self.drawQueue.shadows[i]
      callback()
    end

    love.graphics.setCanvas()
    love.graphics.pop()
  end,

  renderEnd = function(self)
    love.graphics.setCanvas()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.crossSectionCanvas)
    love.graphics.draw(self.floorCanvas)
    love.graphics.draw(self.wallsCanvas)
    love.graphics.draw(self.shadowsCanvas)
  end,

  serialize = function(self)
    return self.grid
  end,

  drawOrder = function()
    return 2
  end
})

return Component.createFactory(blueprint)