local config = require 'config.config'
local userSettings = require 'config.user-settings'

function love.conf(t)
  t.window.fullscreen = userSettings.fullScreen
  -- t.window.highdpi = true
  t.window.title = config.gameTitle
end