local Component = require 'modules.component'
local Color = require 'modules.color'

--[[
  component properties
  @component.icon [STRING] sprite name
  @component.color [TABLE]
  @component.text [TABLE | STRING]
]]
local group = Component.newGroup({
  name = 'hudStatusIcons'
})

local StatusIcons = {}

function StatusIcons.init(self)
  Component.addToGroup(self, 'hud')
end

function StatusIcons.draw(self)
  local i = 0
  for entityId,iconDefinition in pairs(group.getAll()) do

    local offsetX = (i * 24)
    local x, y = self.x + offsetX, self.y
    local AnimationFactory = require 'components.animation-factory'
    local icon = AnimationFactory:newStaticSprite(iconDefinition.icon)
    local width = icon:getWidth()
    Component.get('hudTextSmallLayer'):add(
      iconDefinition.text,
      iconDefinition.color or Color.WHITE,
      x + width - 4,
      y
    )
    love.graphics.setColor(1,1,1)
    love.graphics.draw(AnimationFactory.atlas, icon.sprite, x, y)

    i = i + 1
    group.removeComponent(entityId)
  end
end

return Component.createFactory(StatusIcons)