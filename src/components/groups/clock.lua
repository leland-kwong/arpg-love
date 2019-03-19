local Component = require 'modules.component'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'firstLayer')
  end,
  update = function(self, dt)
    for _,component in pairs(Component.groups.clock.getAll()) do
      component.clock = (component.clock or 0) + dt
    end
  end
})
