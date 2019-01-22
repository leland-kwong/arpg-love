local Component = require 'modules.component'

Component.create({
  id = 'memLeakTest',
  group = 'system',
  update = function()
    for id in pairs(Component.groups.foobar.getAll()) do
      Component.removeFromGroup(id, 'foobar')
    end

    for i=1, 1000 do
      Component.create({
        id = 'foobar'..i,
        group = 'all',
        init = function(self)
          Component.addToGroup(self, 'foobar')
        end
      })

      Component.addToGroup(
        Component.newId(),
        'foobar',
        {}
      )
    end
  end,
})