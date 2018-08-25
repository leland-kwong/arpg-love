-- global game configuration

local f = require 'utils.functional'
local oUtils = require 'utils.object-utils'
local settings = require 'config.user-settings'
local M = {}

oUtils.assign(M, settings)

local xpDiff = 20
M.levelExperienceRequirements = {}
-- setup level experience requirements
(function()
  local req = M.levelExperienceRequirements
  for level=1, 99 do
    table.insert(
      req,
      (level^2+level)/2*xpDiff-(level*xpDiff)
    )
  end
end)()

M.gridSize = 16
M.scaleFactor = 2
M.resolution = {
  w = 640 * 1.5,
  h = 360 * 1.5
}

M.gameTitle = 'Citizen of Nowhere'

return M