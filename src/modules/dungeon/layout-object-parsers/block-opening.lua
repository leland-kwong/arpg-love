return function(obj, grid, origin, cellTranslationsByLayer)
  if not cellTranslationsByLayer then
    return
  end

  local Grid = require 'utils.grid'
  local config = require 'config.config'
  local F = require 'utils.functional'
  local gridWidth, gridHeight = obj.width/config.gridSize, obj.height/config.gridSize
  local VERTICAL, HORIZONTAL = 0, 1
  local orientation = gridWidth > gridHeight and HORIZONTAL or VERTICAL
  local neighbors = (orientation == VERTICAL)
    and {
      {-1, 0},
      {1, 0}
    }
    or {
      {0, -1},
      {0, 1}
    }
  for y=1, gridHeight do
    for x=1, gridWidth do
      local Position = require 'utils.position'
      local gridX, gridY = Position.pixelsToGridUnits(
        obj.x + ((origin.x + (x - 1)) * config.gridSize),
        obj.y + ((origin.y + (y - 1)) * config.gridSize),
        config.gridSize
      )

      local isTraversable = true
      local i = 1
      while (i <= #neighbors) do
        local n = neighbors[i]
        local ox, oy = n[1], n[2]
        local nx, ny = gridX + ox, gridY + oy
        local cell = Grid.get(grid, nx, ny)

        local isEmptyTile = require 'modules.dungeon.modules.is-empty-tile'
        local isMapCell = not isEmptyTile(cell)
        if (not isMapCell) then
          isTraversable = false
        end
        i = i + 1
      end
      if (not isTraversable) then
        Grid.set(grid, gridX, gridY, cellTranslationsByLayer.walls[12])
      end
    end
  end
end