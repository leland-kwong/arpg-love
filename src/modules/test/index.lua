local isDebug = require 'config'.isDebug

if isDebug then
  love.filesystem.load('modules/test/component-test.lua')()
end