local userSettings = require 'config.user-settings'
local Object = require 'utils.object-utils'
local msgBus = require 'components.msg-bus'

local M = {}

local function updateDevMode()
  msgBus.send(msgBus.SET_CONFIG, {
    isDevelopment = userSettings.isDevelopment
  })
end

function M.set(setterFn)
  userSettings = setterFn(userSettings)
  updateDevMode()
  local fs = require 'modules.file-system'
  return fs.saveFile('', 'settings', userSettings)
    :next(function()
      print('settings saved!')
    end, function(err)
      print('[settings save error] '..err)
    end)
end

function M.load()
  local fs = require 'modules.file-system'
  local loadedSettings, ok = fs.loadSaveFile('', 'settings')
  if ok then
    Object.assign(userSettings, loadedSettings, nil, nil, true)
  end
  updateDevMode()
  return userSettings
end

return M