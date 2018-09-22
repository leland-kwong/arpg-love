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
    local actualY = startY + y
    local x = (i % numCols) + 1
    local cell = data[i + 1]
    grid[actualY] = grid[actualY] or {}
    grid[actualY][startX + x] = transformFn and transformFn(cell) or cell
  end
  return grid
end

local cellTranslations = {
  [0] = 1,
  [12] = 0
}

function Dungeon.new(gridBlockNames)
  assert(#gridBlockNames%2 == 0, 'number of grid blocks must be an even number')

  local grid = {}
  for i=0, (#gridBlockNames - 1) do
    local gridBlockName = gridBlockNames[i + 1]
    local gridBlock = loadGridBlock(gridBlockName)
    local numCols = 2
    local x = (i % numCols)
    local y = math.floor(i/numCols)
    local overlapAdjustment = -1 -- this is to prevent walls from doubling up between blocks
    local startX, startY = (x * gridBlock.width),
      (y * gridBlock.height)
    if startX > 0 then
      startX = startX + (overlapAdjustment * x)
    end
    if startY > 0 then
      startY = startY + (overlapAdjustment * y)
    end
    addGridBlock(
      grid,
      gridBlock,
      startX,
      startY,
      function(v)
        return cellTranslations[v] or v
      end
    )
  end
  return grid
end

return Dungeon