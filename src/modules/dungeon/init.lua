--[[
  Generates a dungeon from [Tiled](https://www.mapeditor.org/) layouts.
]]
local iterateGrid = require 'utils.iterate-grid'
local f = require 'utils.functional'

local Dungeon = {}
local function findLayerByName(layers, name)
  for i=1, #layers do
    if layers[i].name == name then
      return layers[i]
    end
  end
end

local objectParsersByType = {
  legendaryEnemy = function(obj, grid, origin)
    local config = require 'config.config'
    local Map = require 'modules.map-generator.index'
    local SpawnerAi = require 'components.spawn.spawn-ai'
    local aiType = require('components.ai.types.ai-'..obj.name)
    local Component = require 'modules.component'
    SpawnerAi({
      grid = grid,
      WALKABLE = Map.WALKABLE,
      rarity = function(ai)
        local Color = require 'modules.color'
        local itemConfig = require 'components.item-inventory.items.config'
        return ai:set('rarityColor', Color.RARITY_LEGENDARY)
          :set('armor', ai.armor * 1.2)
          :set('moveSpeed', ai.moveSpeed * 1.5)
          :set('experience', 10)
      end,
      target = function()
        return Component.get('PLAYER')
      end,
      x = origin.x + (obj.x / config.gridSize),
      y = origin.y + (obj.y / config.gridSize),
      types = {
        aiType
      }
    })
  end,
  aiGroup = function(obj, grid, origin, blockData)
    local config = require 'config.config'
    local Map = require 'modules.map-generator.index'
    local SpawnerAi = require 'components.spawn.spawn-ai'
    local Component = require 'modules.component'

    local aiTypes = require 'components.ai.types'
    local chance = require 'utils.chance'
    local AiTypeGen = chance(f.map(f.keys(aiTypes.types), function(k)
      return {
        chance = 1,
        __call = function()
          return aiTypes.types[k]
        end
      }
    end))
    local spawnTypes = {}
    for i=1, obj.properties.groupSize do
      table.insert(spawnTypes, AiTypeGen())
    end

    SpawnerAi({
      grid = grid,
      WALKABLE = Map.WALKABLE,
      target = function()
        return Component.get('PLAYER')
      end,
      x = origin.x + (obj.x / config.gridSize),
      y = origin.y + (obj.y / config.gridSize),
      types = spawnTypes
    })
  end
}

local function parseObjectsLayer(grid, gridBlockOrigin, objectsLayer, blockData)
  if (not objectsLayer) then
    return
  end
  local objects = objectsLayer.objects
  for i=1, #objects do
    local obj = objects[i]
    local parser = objectParsersByType[obj.type]
    if parser then
      parser(obj, grid, gridBlockOrigin, blockData)
    end
  end
end

local function loadGridBlock(file)
  return require('built.maps.'..file)
end

local function addGridBlock(grid, gridBlockToAdd, startX, startY, transformFn)
  local numCols = gridBlockToAdd.width
  local area = gridBlockToAdd.width * gridBlockToAdd.height
  for i=0, (area - 1) do
    local y = math.floor(i/numCols) + 1
    local x = (i % numCols) + 1
    local actualX = startX + x
    local actualY = startY + y
    grid[actualY] = grid[actualY] or {}
    grid[actualY][actualX] = transformFn((i + 1), x, y)
  end
  return grid
end

local WALL_TILE = 0
local cellTranslationsByLayer = {
  walls = {
    [12] = WALL_TILE
  },
  ground = {
    [1] = 1
  }
}

local defaults = {
  columns = 2
}

function Dungeon.new(gridBlockNames, options)
  local assign = require 'utils.object-utils'.assign
  options = assign({}, defaults, options or {})

  assert(#gridBlockNames%2 == 0, 'number of grid blocks must be an even number')

  local grid = {}
  local numBlocks = #gridBlockNames
  local numCols = options.columns
  local numRows = numBlocks/numCols
  for blockIndex=0, (numBlocks - 1) do
    local gridBlockName = gridBlockNames[blockIndex + 1]
    local gridBlock = loadGridBlock(gridBlockName)

    -- block-level coordinates
    local blockX = (blockIndex % numCols)
    local blockY = math.floor(blockIndex/numCols)

    local overlapAdjustment = -1 -- this is to prevent walls from doubling up between blocks
    local overlapAdjustmentX, overlapAdjustmentY = (overlapAdjustment * blockX), (overlapAdjustment * blockY)
    local origin = {
      x = (blockX * gridBlock.width),
      y = (blockY * gridBlock.height)
    }
    if origin.x > 0 then
      origin.x = origin.x + overlapAdjustmentX
    end
    if origin.y > 0 then
      origin.y = origin.y + overlapAdjustmentY
    end
    addGridBlock(
      grid,
      gridBlock,
      origin.x,
      origin.y,
      function(index, localX, localY)
        local isEdge =
          (blockX == 0 and localX == 1) -- west side
          or ((blockX == numCols - 1) and localX == gridBlock.width) -- east side
          or (blockY == 0 and localY == 1) -- north side
          or ((blockY == numRows - 1) and localY == gridBlock.height) -- south side

        -- close up exits on the perimeter
        if isEdge then
          return WALL_TILE
        end

        local wallLayer = findLayerByName(gridBlock.layers, 'walls')
        local wallValue = wallLayer.data[index]
        if wallValue ~= 0 then
          return cellTranslationsByLayer.walls[wallValue]
        end

        local groundLayer = findLayerByName(gridBlock.layers, 'ground')
        local groundValue = groundLayer.data[index]
        return cellTranslationsByLayer.ground[groundValue]
      end
    )
    local blockData = {
      name = gridBlockName
    }
    parseObjectsLayer(
      grid,
      origin,
      findLayerByName(gridBlock.layers, 'spawn-points'),
      blockData
    )
    parseObjectsLayer(
      grid,
      origin,
      findLayerByName(gridBlock.layers, 'unique-enemies'),
      blockData
    )
  end
  return grid
end

return Dungeon