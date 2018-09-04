local MainMapSolidsFactory = require 'components.map.main-map-solids'

local function generateWallObjects(gridSize, cacheSize)
  local objects = {}

  for i=1, cacheSize + 20 do
    table.insert(
      objects,
      MainMapSolidsFactory.create({
        x = 1 * gridSize,
        y = 1 * gridSize,
        ox = 0,
        oy = 0,
        gridSize = gridSize
      })
    )
  end

  return objects
end

return function(gridSize, cacheSize)
  local WallObjects = generateWallObjects(gridSize, cacheSize)

  -- return the last item and remove it from the pool
  function WallObjects.get(self)
    local obj = self[#self]
    self[#self] = nil
    return obj
  end

  function WallObjects.release(self, obj)
    self[#self + 1] = obj
  end

  return WallObjects
end