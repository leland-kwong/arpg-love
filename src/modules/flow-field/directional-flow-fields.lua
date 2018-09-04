local makeGrid = require 'utils.make-grid'
local Component = require 'modules.component'
local FlowField = require 'modules.flow-field.flow-field'

return function(getTranslatedPosition, WALKABLE)
  assert(type(getTranslatedPosition) == 'function', 'getTranslatedPostion must be a function')
  assert(WALKABLE ~= nil, 'WALKABLE value must be provided')

  -- creates a flow field with virtual walls to steer ai to a certain direction
  local function FlowFieldWithFilter(filter, maxDist, getter)
    return FlowField(function (grid, x, y, dist)
      local row = grid[y]
      local cell = row and row[x]
      local isBlocked = false
      local radiusFromTarget = 2
      if (filter) then
        isBlocked = filter(x, y)
      end
      return
        not isBlocked and
        (cell == WALKABLE) and
        (dist < maxDist)
    end, getter)
  end

  local subFlowFieldSize = 40
  local startX, startY = subFlowFieldSize/2, subFlowFieldSize/2
  local subFlowFieldGrid = makeGrid(subFlowFieldSize, subFlowFieldSize, WALKABLE)
  local function flowFieldGetter(self, x, y)
    local tx, ty = getTranslatedPosition()
    local centerPosition = subFlowFieldSize/2
    local row = self[y - ty + centerPosition]
    return row and row[x - tx + centerPosition]
  end

  -- east direction
  local flowFieldEast = FlowFieldWithFilter(function(x, y)
    return
      (startX - 1 == x and startY == y) or -- W
      (startX == x and startY - 1 == y) or -- N
      (startX == x and startY + 1 == y) or -- S
      (startX - 1 == x and startY - 1 == y) or -- NW
      (startX - 1 == x and startY + 1 == y) -- SW
  end, subFlowFieldSize, flowFieldGetter)(subFlowFieldGrid, startX, startY)
  -- south direction
  local flowFieldSouth = FlowFieldWithFilter(function(x, y)
    return
      (startX - 1 == x and startY == y) or -- W
      (startX - 1 == x and startY - 1 == y) or -- NW
      (startX == x and startY - 1 == y) or -- N
      (startX + 1 == x and startY - 1 == y) or -- NE
      (startX + 1 == x and startY == y) -- E
  end, subFlowFieldSize, flowFieldGetter)(subFlowFieldGrid, startX, startY)
  -- west direction
  local flowFieldWest = FlowFieldWithFilter(function(x, y)
    return
      (startX == x and startY - 1 == y) or -- N
      (startX + 1 == x and startY - 1 == y) or -- NE
      (startX + 1 == x and startY == y) or -- E
      (startX + 1 == x and startY + 1 == y) or -- SE
      (startX == x and startY + 1 == y) -- S
  end, subFlowFieldSize, flowFieldGetter)(subFlowFieldGrid, startX, startY)
  -- north opening
  local flowFieldNorth = FlowFieldWithFilter(function(x, y)
    return
      (startX - 1 == x and startY == y) or -- W
      (startX - 1 == x and startY + 1 == y) or -- SW
      (startX == x and startY + 1 == y) or -- S
      (startX + 1 == x and startY + 1 == y) or -- SE
      (startX + 1 == x and startY == y) -- E
  end, subFlowFieldSize, flowFieldGetter)(subFlowFieldGrid, startX, startY)

  return {
    flowFieldNorth,
    flowFieldEast,
    flowFieldSouth,
    flowFieldWest
  }
end