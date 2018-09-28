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
    SpawnerAi.create({
      grid = grid,
      WALKABLE = Map.WALKABLE,
      rarity = function(ai)
        local Color = require 'modules.color'
        return ai:set('rarityColor', Color.RARITY_LEGENDARY)
          :set('armor', ai.armor * 1.2)
          :set('moveSpeed', ai.moveSpeed * 1.5)
          :set('maxHealth', ai.maxHealth * 8)
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
  end
}

local function parseObjectsLayer(grid, gridBlockOrigin, objectsLayer)
  if (not objectsLayer) then
    return
  end
  local objects = objectsLayer.objects
  for i=1, #objects do
    local obj = objects[i]
    local parser = objectParsersByType[obj.type]
    if parser then
      parser(obj, grid, gridBlockOrigin)
    end
  end
end

local function loadGridBlock(file)
  return require('built.maps.'..file)
end

local function addGridBlock(grid, gridBlockToAdd, startX, startY, transformFn)
  local layer = findLayerByName(gridBlockToAdd.layers, 'walls')
  local data = layer.data
  for i=0, (#data - 1) do
    local numCols = layer.width
    local y = math.floor(i/numCols) + 1
    local x = (i % numCols) + 1
    local actualX = startX + x
    local actualY = startY + y
    local cell = data[i + 1]
    grid[actualY] = grid[actualY] or {}
    grid[actualY][actualX] = transformFn and transformFn(cell, x, y) or cell
  end
  return grid
end

local cellTranslations = {
  [0] = 1,
  [12] = 0,
  WALL = 0,
}

function Dungeon.new(gridBlockNames)
  assert(#gridBlockNames%2 == 0, 'number of grid blocks must be an even number')

  local grid = {}
  local numBlocks = #gridBlockNames
  local numCols = 2
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
      function(v, localX, localY)
        local isEdge =
          (blockX == 0 and localX == 1) -- west side
          or ((blockX == numCols - 1) and localX == gridBlock.width) -- east side
          or (blockY == 0 and localY == 1) -- north side
          or ((blockY == numRows - 1) and localY == gridBlock.height) -- south side
        -- close up exits on the perimeter
        if isEdge then
          return cellTranslations.WALL
        end

        return cellTranslations[v] or v
      end
    )
    parseObjectsLayer(
      grid,
      origin,
      findLayerByName(gridBlock.layers, 'objects')
    )
  end
  return grid
end

return Dungeon