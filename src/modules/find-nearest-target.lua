local Position = require 'utils.position'

local function hasItem(list, item)
  local found = false
  local i = 1
  while (i <= #list) and (not found) do
    local t = list[i]
    found = item == t
    i = i + 1
  end
  return found
end

--[[
  maxSeekRadius [NUMBER] - Maximum pixel radius to seek out enemies
]]
local function findNearestTarget(
  collisionWorld, ignoreTargets, startX, startY, maxSeekRadius, lineOfSightFn, gridSize
)
  local los = lineOfSightFn

  local nearestEnemyFound = nil
  local i = 1

  while (i <= maxSeekRadius) and (not nearestEnemyFound) do
    local width, height = maxSeekRadius * 2, maxSeekRadius * 2
    local collisionX, collisionY = startX, startY
    local items, len = collisionWorld:queryRect(
      collisionX - width/2,
      collisionY - height/2,
      width,
      height,
      function(item)
        if (not nearestEnemyFound) and item.group == 'ai' then
          local target = item.parent
          local isAlreadyFound = ignoreTargets and hasItem(ignoreTargets, target)
          if los then
            local gx1, gy1 = Position.pixelsToGridUnits(startX, startY, gridSize)
            local gx2, gy2 = Position.pixelsToGridUnits(target.x, target.y, gridSize)
            local canSeeTarget = los(gx1, gy1, gx2, gy2)
            if (not isAlreadyFound) and canSeeTarget then
              nearestEnemyFound = target
            end
          else
            nearestEnemyFound = target
          end
        end
        return false
      end
    )
    i = i + 1
  end

  return nearestEnemyFound
end

return findNearestTarget