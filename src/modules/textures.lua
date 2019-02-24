local iceTexture = love.graphics.newImage('built/images/frost-texture-2.jpg')
iceTexture:setFilter('linear')
iceTexture:setWrap('repeat')

local defaultTexture = love.graphics.newImage('built/images/white-texture-128x128.png')
defaultTexture:setWrap('repeat')

return {
  ice = iceTexture,
  default = defaultTexture
}