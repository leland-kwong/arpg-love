local userSettings = require 'config.user-settings'
local assign = require 'utils.object-utils'.assign

local M = {}

function M.set(setterFn)
  userSettings = setterFn(userSettings)
  local fs = require 'modules.file-system'
  return fs.saveFile('/', 'settings', userSettings)
    :next(function()
      print('settings saved!')
    end, function(err)
      print('[settings save error] '..err)
    end)
end

function M.load()
  local fs = require 'modules.file-system'
  local loadedSettings = fs.loadSaveFile('/', 'settings')
  print(
    require('utils.inspect')(loadedSettings)
  )
  assign(userSettings, loadedSettings)
  return loadedSettings
end

-- M.set()
M.load()

return M