local json = require 'lua_modules.json'
local Animation = require 'modules.animation'

love.graphics.setDefaultFilter('nearest', 'nearest')
local spriteAtlas = love.graphics.newImage('built/sprite.png')
local spriteData = json.decode(
  love.filesystem.read('built/sprite.json')
)

return Animation(spriteData, spriteAtlas, 1)