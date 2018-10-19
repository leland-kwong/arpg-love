local Component = require 'modules.component'
local Color = require 'modules.color'

Component.newGroup({
  name = 'guiDrawBox'
})

local defaults = {
  backgroundColor = {Color.multiplyAlpha(Color.DARK_GRAY, 0.94)},
  borderColor = Color.SKY_BLUE,
  borderWidth = 1
}

return function()
  local gfx = love.graphics
  for _,entity in pairs(Component.groups.guiDrawBox.getAll()) do
    local x, y, width, height = entity.x, entity.y, entity.width, entity.height

    -- border
    local oLineWidth = love.graphics.getLineWidth()
    gfx.setLineWidth(entity.borderWidth or defaults.borderWidth)
    gfx.setColor(entity.borderColor or defaults.borderColor)
    gfx.rectangle('line', x, y, width, height)
    gfx.setLineWidth(oLineWidth)

    -- background
    gfx.setColor(entity.backgroundColor or defaults.backgroundColor)
    gfx.rectangle('fill', x, y, width, height)
  end
end