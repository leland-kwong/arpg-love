local O = require 'utils.object-utils'
local Grid = require 'utils.grid'
local grid = {
  {1, 1},
  {1, 1}
}

local index = Grid.getIndexByCoordinate(grid, 1, 2)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 3, '[grid error] incorrect index')
assert(x == 1, y == 2, '[grid error] incorrect coords')

local index = Grid.getIndexByCoordinate(grid, 2, 2)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 4, '[grid error] incorrect index')
assert(x == 2, y == 2, '[grid error] incorrect coords')

local index = Grid.getIndexByCoordinate(grid, 1, 1)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 1, '[grid error] incorrect index')
assert(x == 1, y == 1, '[grid error] incorrect coords')

local copy = Grid.map(grid, function(v)
  return v + 1
end)
assert(#copy == 2) -- num rows
assert(#copy[1] == 2) -- num cols
assert(
  O.deepEqual(
    copy,
    {
      {2, 2},
      {2, 2}
    }
  )
)