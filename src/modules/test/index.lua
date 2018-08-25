local isDebug = require 'config.config'.isDebug

if isDebug then
  love.filesystem.load('modules/test/component-test.lua')()
  love.filesystem.load('modules/test/queue-test.lua')()
end