local Component = require 'modules.component'

local group = Component.newGroup({
  name = 'hudStatusIcons'
})

local StatusIcons = {}

function StatusIcons.init(self)
  Component.addToGroup(self, 'hud')
end

function StatusIcons.draw(self)
  local i = 0
  for entityId,renderer in pairs(group.getAll()) do
    local offsetX = (i * 24)
    renderer(self.x + offsetX, self.y)
    i = i + 1
    group.removeComponent(entityId)
  end
end

return Component.createFactory(StatusIcons)