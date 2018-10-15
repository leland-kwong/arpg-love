local Component = require 'modules.component'
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
      }):setParent(Component.get('MAIN_SCENE'))
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
    obj:enable()
    return obj
  end

  function WallObjects.release(self, obj)
    -- we should always insert to the beginning so we properly cycle through all the objects
    table.insert(self, 1, obj)
    obj:disable()
  end

  return WallObjects
end