local Color = require 'modules.color'
local gfx = love.graphics

local defaults = {
  backgroundColor = {Color.multiplyAlpha(Color.DARK_GRAY, 0.94)},
  borderColor = Color.SKY_BLUE,
  borderWidth = 1
}

return function(component, options)
  local r,g,b,a = love.graphics.getColor()

  options = options or defaults
  local x, y, width, height = component.x, component.y, component.width, component.height

  -- background
  gfx.setColor(options.backgroundColor or defaults.backgroundColor)
  gfx.rectangle('fill', x, y, width, height)

  -- border
  local oLineWidth = love.graphics.getLineWidth()
  gfx.setLineWidth(options.borderWidth or defaults.borderWidth)
  gfx.setColor(options.borderColor or defaults.borderColor)
  gfx.rectangle('line', x, y, width, height)
  gfx.setLineWidth(oLineWidth)

  love.graphics.setColor(r,g,b,a)
end