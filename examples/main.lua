local glyphs = ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
local font = love.graphics.newImageFont('font/font.png', glyphs)
love.graphics.setFont(font)

function love.draw()
  love.graphics.print('Lorem ipsum dolor')
end