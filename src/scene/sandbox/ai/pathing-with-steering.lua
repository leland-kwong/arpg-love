local pprint = require'utils.pprint'
local normalize = require'utils.position'.normalizeVector

local function isZeroVector(vx, vy)
  return vx == 0 and vy == 0
end

local function getFlowFieldValue(flowField, gridX, gridY)
  local row = flowField[gridY]
  local v = row[gridX]
  if not v then
    return 0, 0, 0
  end
  return v[1], v[2], v[3]
end

return function (self, flowField, grid, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX, gridY)
  -- total vectors
  local vx, vy = 0,0
  local clearance = self.scale
  -- adjust vector if part of the agent will collide with a wall
  if clearance == 1 and isZeroVector(vx, vy) then
    return 0,0
  elseif clearance > 1 and clearance <= 2 then
    local vx2, vy2 = getFlowFieldValue(flowField, gridX + 1, gridY)
    local vx3, vy3 = getFlowFieldValue(flowField, gridX + 1, gridY + 1)
    local vx4, vy4 = getFlowFieldValue(flowField, gridX, gridY + 1)

    local shouldStop = isZeroVector(vx1, vy1) or
      isZeroVector(vx2, vy2) or
      isZeroVector(vx3, vy3) or
      isZeroVector(vx4, vy4)
    if shouldStop then
      return 0,0
    end

    -- -- both 1 and 2 point in same horizontal direction
    -- if (vx1 == vx2) and (vy1 == 0 and vy2 == 0) then
    --   if (
    --     -- moving right and right side clear
    --     vx1 > 0 and
    --     (grid[gridY][gridX + 2] == WALKABLE) and
    --     (grid[gridY + 1][gridX + 2] == WALKABLE) and
    --     (grid[gridY + 2][gridX + 2] == WALKABLE)
    --   ) or (
    --     -- moving left and left side clear
    --     vx1 < 0 and
    --     (grid[gridY][gridX - 1] == WALKABLE) and
    --     (grid[gridY + 1][gridX - 1] == WALKABLE) and
    --     (grid[gridY + 2][gridX - 1] == WALKABLE)
    --   )
    --   then
    --     vy3 = 0
    --     vy4 = 0
    --   end
    -- end

    -- -- both 1 and 2 point in same vertical direction
    -- if (vy1 == vy4) and (vx1 == 0 and vx4 == 0) then
    --   local _vx1, _vy1 = getFlowFieldValue(flowField, gridX - 1, gridY)
    --   local _vx2, _vy2 = getFlowFieldValue(flowField, gridX - 1, gridY + 1)
    --   if (
    --     -- moving down and bottom side clear
    --     vy1 > 0 and _vx1 == 1 and _vx2 == 1 and
    --     grid[gridY - 2][gridX] == WALKABLE and
    --     grid[gridY - 2][gridX + 1] == WALKABLE
    --   ) or (
    --     -- moving left and left side clear
    --     vy1 < 0 and _vx1 == 1 and _vx2 == 1
    --   )
    --   then
    --     vx2 = 0
    --     vx3 = 0
    --   end
    -- end

    local movingSouthwest = (vx1 == -1) and (vy1 == 1)
    if movingSouthwest then
      local vxBlock, vyBlock = getFlowFieldValue(flowField, gridX, gridY + 2)
      if vyBlock == -1 then
        vx1 = -1
        vy1 = 0
        vx2 = -1
        vy2 = 0
        vy3 = -1
        vy4 = -1
      end
    end

    -- southeast and southeast corner blocked
    local movingSoutheast = vx1 == 1 and vy1 == 1
    if movingSoutheast and (grid[gridY + 2][gridX + 2] ~= WALKABLE) then
      if vx3 == 1 and vx4 == 1 then
        vx1 = 1
        vy1 = 0
        vx2 = 1
        vy2 = 0
        vy3 = -1
        vy4 = -1
      else
        vx1 = -1
        vy1 = 1
        vx2 = -1
        vy2 = 1
      end
    end

    -- northeast and northeast corner blocked
    local movingNortheast = vx1 == 1 and vy1 == -1
    if movingNortheast and (grid[gridY - 1][gridX + 2] ~= WALKABLE) then
      vx1 = -1
      vy1 = -1
      vx3 = -1
      vy3 = -1
    end

    local movingLeftAndRight = vx1 == -1 and vx2 == 1
    if movingLeftAndRight then
      -- use vector from upper-left quadrant
      vx2 = 0
      vx3 = 0
    end

    vx = vx1 + vx2 + vx3 + vx4
    vy = vy1 + vy2 + vy3 + vy4
  end
  return normalize(vx, vy)
end