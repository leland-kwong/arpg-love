local Grid = require 'utils.grid'
local grid = {
  {1, 1, 1, 1},
  {1, 1, 1, 1}
}

local index = Grid.getIndexByCoordinate(grid, 1, 2)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 5, '[grid error] incorrect index')
assert(x == 1, y == 2, '[grid error] incorrect coords')

local index = Grid.getIndexByCoordinate(grid, 4, 2)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 8, '[grid error] incorrect index')
assert(x == 4, y == 2, '[grid error] incorrect coords')

local index = Grid.getIndexByCoordinate(grid, 1, 1)
local x, y = Grid.getCoordinateByIndex(grid, index)
assert(index == 1, '[grid error] incorrect index')
assert(x == 1, y == 1, '[grid error] incorrect coords')