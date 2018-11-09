local config = require 'config.config'

function love.conf(t)
  t.window.fullscreen = true
  -- t.window.highdpi = true
  t.window.title = config.gameTitle
end