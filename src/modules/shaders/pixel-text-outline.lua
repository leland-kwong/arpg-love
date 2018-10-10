local shaderSource = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local defaultOutlineColor = {0,0,0,1}
local shader = love.graphics.newShader(shaderSource)
local textW, textH = 16, 16
local spriteSize = {textW, textH}

local PixelTextShader = {}

function PixelTextShader.attach(outlineColor, alpha)
  love.graphics.setShader(shader)
  shader:send('sprite_size', spriteSize)
  shader:send('outline_width', 2/textW)
  shader:send('outline_color', outlineColor or defaultOutlineColor)
  shader:send('use_drawing_color', true)
  shader:send('include_corners', true)
  shader:send('alpha', alpha or 1)
end

function PixelTextShader.detach()
  love.graphics.setShader()
end

return PixelTextShader