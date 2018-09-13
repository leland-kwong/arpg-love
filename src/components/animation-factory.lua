local json = require 'lua_modules.json'
local Animation = require 'modules.animation'

local spriteAtlas = love.graphics.newImage('built/sprite.png')
local spriteAtlasLinear = love.graphics.newImage('built/sprite.png')
local spriteData = json.decode(
  love.filesystem.read('built/sprite.json')
)

return Animation(spriteData, spriteAtlas, 1)