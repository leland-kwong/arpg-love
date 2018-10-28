-- 2-d grid utilities

local Grid = {}

function Grid.get(grid, x, y)
  local row = grid[y]
  return row and row[x]
end

function Grid.set(grid, x, y, value)
  local row = grid[y]
  if (not row) then
    row = {}
    grid[y] = row
  end
  row[x] = value
  return value
end

function Grid.forEach(grid, callback)
  for y,row in pairs(grid) do
    for x,colValue in pairs(row) do
      callback(colValue, x, y)
    end
  end
end

function Grid.getIndexByCoordinate(numCols, x, y)
  return (y * numCols) + x
end

local floor = math.floor
function Grid.getCoordinateByIndex(numCols, index)
  local y = floor(index / numCols)
  local x = index - (y * numCols)
  return x, y
end

return Grid