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

return Grid