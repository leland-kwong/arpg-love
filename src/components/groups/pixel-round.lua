local Component = require 'modules.component'
local Math = require 'utils.math'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'all')
  end,
  update = function()
    for _,c in pairs(Component.groups.pixelRound.getAll()) do
      c.x = Math.round(c.x)
      c.y = Math.round(c.y)
    end
  end
})