local loadJsonFile = require 'utils.load-json-file'
local Animation = require 'modules.animation'

love.graphics.setDefaultFilter('nearest', 'nearest')
local spriteAtlas = love.graphics.newImage('built/sprite.png')
local spriteData = loadJsonFile('built/sprite.json')
local createAnimation = Animation(spriteData, spriteAtlas, 4)

return {
  create = createAnimation,
  spriteAtlas = spriteAtlas,
  spriteData = spriteData
}