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
  local Db = require 'modules.database'
  return Db.load(''):put('settings', userSettings)
    :next(function()
      print('settings saved!')
    end, function(err)
      print('[settings save error] '..err)
    end)
end

function M.load()
  local Db = require 'modules.database'
  local loadedSettings, err = Db.load(''):get('settings')
  if (not err) then
    Object.assign(userSettings, loadedSettings, nil, nil, true)
  end
  updateDevMode()
  return userSettings
end

return M