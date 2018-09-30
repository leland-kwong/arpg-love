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

local function generateLoot(x, y, item)
  local LootGenerator = require'components.loot-generator.loot-generator'
  if not item then
    return
  end
  local mapGrid = Component.get('MAIN_SCENE').mapGrid
  local dropX, dropY = getDroppablePosition(x, y, mapGrid)
  LootGenerator.create({
    x = dropX,
    y = dropY,
    item = item,
  }):setParent(parent)
end

return {
  system = Component.newSystem({
    onComponentEnter = function(_, c)
      local randomItem = lootAlgorithm()
      return generateLoot(c.x, c.y, randomItem)
    end
  })
}