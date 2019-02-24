local bresenhamLine = require'utils.bresenham-line'
local collisionGroups = require 'modules.collision-groups'
local collisionWorlds = require 'components.collision-worlds'
local config = require 'config.config'

local obstacleFilter = function(item)
  return collisionGroups.matches(item.group, 'obstacle')
end

-- return [FUNCTION] - a line of sight checker based on the provided grid and walkable params
return function(grid, WALKABLE, debugFn, isDevelopment)
  local prevX, prevY

  -- return [BOOLEAN] - true if line of sight is valid
  local function checkLineOfSight(x1, y1, x2, y2, filter)
    local gs = config.gridSize
    local items, len = collisionWorlds.map:querySegment(x1, y1, x2, y2, filter or obstacleFilter)
    return len == 0
  end

  return checkLineOfSight
end