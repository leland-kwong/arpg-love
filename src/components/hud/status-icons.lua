local Component = require 'modules.component'

local StatusIcons = {}

function StatusIcons.init(self)
  Component.addToGroup(self, 'hud')
end

function StatusIcons.addIcon(self, iconRenderFn)
  self.iconRenderers = self.iconRenderers or {}
  table.insert(self.iconRenderers, iconRenderFn)
  return self
end

local EMPTY = {}

function StatusIcons.draw(self)
  for i=1, #(self.iconRenderers or EMPTY) do
    local offsetX = ((i - 1) * 24)
    local renderer = self.iconRenderers[i]
    renderer(self.x + offsetX, self.y)
  end

  -- reset list
  self.iconRenderers = nil
end

return Component.createFactory(StatusIcons)