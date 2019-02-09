local Position = require 'utils.position'
local Math = require 'utils.math'
local collisionGroups = require 'modules.collision-groups'
local noop = require 'utils.noop'

--[[
  maxSeekRadius [NUMBER] - Maximum pixel radius to seek out enemies
]]
local function findNearestTarget(
  collisionWorld, startX, startY, maxSeekRadius, lineOfSightFn, gridSize, filter
)
  local los = lineOfSightFn
  filter = filter or noop

  local nearestEnemyFound = nil
  local shortestEnemyDist = 10 * 10
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
        if collisionGroups.matches(item.group, collisionGroups.create(collisionGroups.enemyAi, collisionGroups.environment)) then
          local target = item.parent
          local isValidTarget = filter(target)
          if isValidTarget and los then
            local gx1, gy1 = Position.pixelsToGridUnits(startX, startY, gridSize)
            local gx2, gy2 = Position.pixelsToGridUnits(target.x, target.y, gridSize)
            local canSeeTarget = los(startX, startY, target.x, target.y)
            if canSeeTarget then
              local dist = Math.dist(gx1, gy1, gx2, gy2)
              if dist < shortestEnemyDist then
                shortestEnemyDist = dist
                nearestEnemyFound = target
              end
            end
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