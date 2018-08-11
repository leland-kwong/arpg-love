-- Returns coordinates for closest walkable neighboring position

local adjacentPositions = {
  {-1, -1}, -- NW
  {0, -1}, -- N
  {1, -1}, -- NE
  {-1, 0}, -- W
  {1, 0}, -- E
  {-1, 1}, -- SW
  {0, -1}, -- S
  {1, -1} -- SE
}

local function getAdjacentWalkablePosition(grid, x, y, WALKABLE)
  for i=1, #adjacentPositions do
    local pos = adjacentPositions[i]
    local posX, posY = x + pos[1], y + pos[2]
    local row = grid[posY]
    local posValue = row and row[posX]
    if posValue == WALKABLE then
      return posX, posY
    end
  end
end

return getAdjacentWalkablePosition