local defaultOutlineColor = {0,0,0,1}
local textW, textH = 16, 16
local defaultSpriteSize = {textW, textH}
local Shaders = require 'modules.shaders'

local shader = Shaders('pixel-outline.fsh')

local PixelTextShader = {}

function PixelTextShader.attach(outlineColor, alpha, outlineWidth, spriteSize)
  spriteSize = spriteSize or defaultSpriteSize
  love.graphics.setShader(
    shader
  )
  shader:send('enabled', true)
  shader:send('sprite_size', spriteSize or defaultSpriteSize)
  shader:send('outline_width', (outlineWidth or 2)/spriteSize[1])
  shader:send('outline_color', outlineColor or defaultOutlineColor)
  shader:send('include_corners', true)
  love.graphics.setColor(1,1,1,alpha)
end

function PixelTextShader.detach()
  shader:send('enabled', false)
end

return PixelTextShader