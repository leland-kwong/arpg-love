local Component = require 'modules.component'
local lootAlgorithm = require 'components.loot-generator.algorithm-1'
local config = require 'config.config'
local Map = require 'modules.map-generator.index'

local random = math.random
local Position = require 'utils.position'
local function getDroppablePosition(posX, posY, mapGrid, callCount)
  -- FIXME: prevent infinite recursion from freezing the game. This is a temporary fix.
  callCount = (callCount or 0)

  local dropX, dropY = posX + random(0, 16), posY + random(0, 16)
  local gridX, gridY = Position.pixelsToGridUnits(dropX, dropY, config.gridSize)
  local isWalkable = mapGrid[gridY][gridX] == Map.WALKABLE
  if (not isWalkable) and (callCount < 10) then
    return getDroppablePosition(
      posX,
      posY,
      mapGrid,
      (callCount + 1)
    )
  end
  return dropX, dropY
end

local function generateLoot(c, item)
  local LootGenerator = require'components.loot-generator.loot-generator'
  local mapGrid = Component.get('MAIN_SCENE').mapGrid
  local dropX, dropY = getDroppablePosition(c.x, c.y, mapGrid)
  LootGenerator.create({
    x = dropX,
    y = dropY,
    item = lootAlgorithm(),
  }):setParent(parent)
end

return {
  system = Component.newSystem({
    onComponentEnter = function(_, c)
      return generateLoot(c)
    end
  })
}