local Component = require 'modules.component'
local Color = require 'modules.color'
local lru = require 'utils.lru'
local AnimationFactory = require 'components.animation-factory'

local iconSize = 18
local iconCache = {
  cache = lru.new(400),
  get = function(self, icon)
    local animation = self.cache:get(icon)
    if (not animation) then
      animation = AnimationFactory:new({ icon })

      local x,y,w,h = animation.sprite:getViewport()
      local ox, oy = math.ceil(math.max(0, w - iconSize)/2),
        math.ceil(math.max(0, h - iconSize)/2)
      animation.sprite:setViewport(x + ox, y + oy, iconSize, iconSize)

      self.cache:set(icon, animation)
    end

    return animation
  end
}

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
    local icon = iconCache:get(iconDefinition.icon)
    Component.get('hudTextSmallLayer'):add(
      iconDefinition.text,
      iconDefinition.color or Color.WHITE,
      x + iconSize - 5,
      y
    )
    love.graphics.setColor(1,1,1)
    love.graphics.draw(AnimationFactory.atlas, icon.sprite, x, y)

    i = i + 1
    group.removeComponent(id)
  end
end

return Component.createFactory(StatusIcons)