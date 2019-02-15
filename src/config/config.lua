-- global game configuration

local msgBus = require 'components.msg-bus'
local f = require 'utils.functional'
local oUtils = require 'utils.object-utils'

local M = {}

msgBus.on(msgBus.SET_CONFIG, function(msgValue)
  local configChanges = msgValue
  local oUtils = require 'utils.object-utils'
  local originalState = oUtils.clone(M)
  local newState = oUtils.assign(M, configChanges)
  msgBus.send('SET_CONFIG_SUCCESS', {
    old = originalState,
    new = newState,
  })
end)

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
M.scaleFactor = 3
M.scale = M.scaleFactor
M.resolution = {
  w = 640,
  h = 360
}

M.isDevelopment = false
M.enableConsole = false
M.performanceProfile = false
M.debugDrawQueue = false
M.collisionDebug = false

M.performacneProfileEnabled = false

M.gameTitle = 'Citizen of Nowhere'

local getVersion = require 'modules.get-version'
M.version = getVersion()

return M