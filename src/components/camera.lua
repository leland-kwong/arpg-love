local Camera = require 'modules.camera'
local userSettings = require 'config.user-settings'

return Camera({
  lerp = function()
    return userSettings.camera.speed
  end
})