local shaderSource = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local defaultOutlineColor = {0,0,0,1}
local shader = love.graphics.newShader(shaderSource)
local textW, textH = 16, 16
local defaultSpriteSize = {textW, textH}

local PixelTextShader = {}

function PixelTextShader.attach(outlineColor, alpha, outlineWidth, spriteSize)
  spriteSize = spriteSize or defaultSpriteSize
  love.graphics.setShader(shader)
  shader:send('sprite_size', spriteSize or defaultSpriteSize)
  shader:send('outline_width', (outlineWidth or 2)/spriteSize[1])
  shader:send('outline_color', outlineColor or defaultOutlineColor)
  shader:send('use_drawing_color', true)
  shader:send('include_corners', true)
  shader:send('alpha', alpha or 1)
end

function PixelTextShader.detach()
  love.graphics.setShader()
end

return PixelTextShader