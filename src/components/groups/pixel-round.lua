local Component = require 'modules.component'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'all')
  end,
  update = function()
    for _,c in pairs(Component.groups.pixelRound.getAll()) do
      c.x = math.floor(c.x)
      c.y = math.floor(c.y)
    end
  end
})