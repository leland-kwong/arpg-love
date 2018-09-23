--[[
  Generates a dungeon from [Tiled](https://www.mapeditor.org/) layouts.
]]
local iterateGrid = require 'utils.iterate-grid'

local Dungeon = {}

local function loadGridBlock(file)
  local gridBlock = require('built.maps.'..file)
  local layer = gridBlock.layers[2]
  return layer
end

local function addGridBlock(grid, gridBlockToAdd, startX, startY, transformFn)
  local data = gridBlockToAdd.data
  for i=0, (#data - 1) do
    local numCols = gridBlockToAdd.width
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
    local startX, startY = (blockX * gridBlock.width),
      (blockY * gridBlock.height)
    if startX > 0 then
      startX = startX + overlapAdjustmentX
    end
    if startY > 0 then
      startY = startY + overlapAdjustmentY
    end
    addGridBlock(
      grid,
      gridBlock,
      startX,
      startY,
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
  end
  return grid
end

return Dungeon