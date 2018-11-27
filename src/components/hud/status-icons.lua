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
  local iconsSortedById = {}
  local components = group.getAll()
  for entityId in pairs(components) do
    table.insert(iconsSortedById, entityId)
  end
  table.sort(iconsSortedById)
  for _,id in ipairs(iconsSortedById) do
    local iconDefinition = components[id]
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
    group.removeComponent(id)
  end
end

return Component.createFactory(StatusIcons)