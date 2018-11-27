local isDevelopment = require 'config.config'.isDevelopment

if isDevelopment then
  love.filesystem.load('modules/test/component-test.lua')()
  love.filesystem.load('modules/test/queue-test.lua')()

  local fs = require 'modules.file-system'
  require 'modules.file-system.test'(fs)

  require 'utils.test.index'
end