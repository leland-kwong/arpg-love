-- global game configuration

local msgBus = require 'components.msg-bus'
local f = require 'utils.functional'
local oUtils = require 'utils.object-utils'
local M = {}

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

M.autoSave = true

M.gridSize = 16
M.scaleFactor = 2
M.scale = M.scaleFactor
M.resolution = {
  w = 640 * 1.5,
  h = 360 * 1.5
}
M.window = {
  width = M.resolution.w * M.scale,
  height = M.resolution.h * M.scale
}

M.isDevelopment = false
M.enableConsole = false
M.performanceProfile = false
M.debugDrawQueue = false
M.collisionDebug = false

M.gameTitle = 'Citizen of Nowhere'
M.version = '1.1.0-alpha'

return M