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
  return v.x, v.y, v.dist
end

local function isUpLeft(flowField, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX - 1, gridY)
  local vx2, vy2 = getFlowFieldValue(flowField, gridX - 1, gridY + 1)
  local vx3, vy3 = getFlowFieldValue(flowField, gridX, gridY + 1)
  return
    vx3 == 0 and vy3 == -1 and
    (
      vx1 == -1 and vy1 == 0 or
      vx2 == -1 and vy2 == 0
    )
end

local function isUpRight(flowField, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX + 2, gridY)
  local vx2, vy2 = getFlowFieldValue(flowField, gridX + 2, gridY + 1)
  return
    vx1 == 1 and vy1 == 0 or
    vx2 == 1 and vy2 == 0
end

local function isLeftUp(flowField, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX, gridY - 1)
  local vx2, vy2 = getFlowFieldValue(flowField, gridX + 1, gridY - 1)
  return
    vx1 == 0 and vy1 == -1 or
    vx2 == 0 and vy2 == -1
end

local function isLeftDown(flowField, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX, gridY + 1)
  local vx2, vy2 = getFlowFieldValue(flowField, gridX + 1, gridY + 1)
  return
    vx1 == 0 and vy1 == 1 or
    vx2 == 0 and vy2 == 1
end

local function isDownLeft(flowField, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX - 1, gridY)
  local vx2, vy2 = getFlowFieldValue(flowField, gridX - 1, gridY + 1)
  local vx3, vy3 = getFlowFieldValue(flowField, gridX + 2, gridY - 1)
  return
    vx3 == 0 and vy3 == 1 and
    (
      vx1 == -1 and vy1 == 0 or
      vx2 == -1 and vy2 == 0
    )
end

return function (self, flowField, grid, gridX, gridY)
  local vx1, vy1 = getFlowFieldValue(flowField, gridX, gridY)
  -- total vectors
  local vx, vy = 0,0
  local clearance = self.scale
  -- adjust vector if part of the agent will collide with a wall
  if clearance == 1 then
    if isZeroVector(vx1, vy1) then
      return 0,0
    end
    vx, vy = vx1, vy1
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

    -- if isUpLeft(flowField, gridX, gridY) then
    --   vy1 = -1
    --   vy2 = -1
    -- end

    -- if isUpRight(flowField, gridX, gridY) then
    --   vy1 = -1
    --   vy2 = -1
    -- end

    -- if isLeftUp(flowField, gridX, gridY) then
    --   vx1 = -1
    --   vx4 = -1
    -- end

    -- if isLeftDown(flowField, gridX, gridY) then
    --   vx1 = -1
    --   vx4 = -1
    -- end

    -- if isDownLeft(flowField, gridX, gridY) then
    --   vy3 = 1
    --   vy4 = 1
    -- end

    vx = vx1 + vx2 + vx3 + vx4
    vy = vy1 + vy2 + vy3 + vy4
  end
  return normalize(vx, vy)
end