local userSettings = require 'config.user-settings'
local Object = require 'utils.object-utils'
local msgBus = require 'components.msg-bus'

local M = {}

local function updateDevMode()
  local isDevelopment = userSettings.isDevelopment
  msgBus.send(msgBus.SET_CONFIG, {
    isDevelopment = isDevelopment,
    scale = userSettings.display.scale
  })
  _DEVELOPMENT_ = isDevelopment
end

function M.set(setterFn)
  userSettings = setterFn(userSettings)
  updateDevMode()
  local Db = require 'modules.database'
  return Db.load(''):put('settings', userSettings)
    :next(function()
      print('settings saved!')

      local config = require 'config.config'
      if config.isDevelopment then
        local Color = require 'modules.color'
        msgBus.send(msgBus.NOTIFIER_NEW_EVENT, {
          title = 'settings saved',
          description = {
            Color.WHITE,
            love.filesystem.getSaveDirectory()
          }
        })
      end
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