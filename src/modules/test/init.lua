local isDevelopment = require 'config.config'.isDevelopment

if isDevelopment then
  love.filesystem.load('modules/test/component-test.lua')()
  love.filesystem.load('modules/test/queue-test.lua')()

  require 'utils.test.index'
end