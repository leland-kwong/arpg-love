local function getIndexByCoordinate(grid)
  local maxCols = #grid[1]
  return function (x, y)
    return (y * maxCols) + x
  end
end

return getIndexByCoordinate