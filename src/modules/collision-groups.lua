local Enum = require 'utils.enum'

local allowedLabels = Enum({
  'ai',
  'enemyAi',
  'obstacle',
  'player',
  'projectile',
  'environment',
  'floorItem',
  'hotSpot',
  'invisible',
  'interact'
})

local groupMatch = require 'utils.group-match'
-- checks if at least one value in groupA exists in groupB
local M = {
  matches = function(groupA, groupB)
    return groupMatch(groupA, groupB, allowedLabels)
  end
}
M.__index = allowedLabels
setmetatable(M, M)

return M