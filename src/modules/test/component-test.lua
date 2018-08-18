local Component = require 'modules.component'

local group = Component.newGroup()
local calls = {}

local blueprint = {
  x = 0,
  y = 0,
  foo = 'foo',

  init = function(self)
    calls.init = {
      {self}
    }
  end,

  update = function(self, dt)
    calls.update = {
      {self, dt}
    }
  end,

  draw = function(self)
    calls.draw = {
      {self}
    }
  end,

  final = function(self)
    calls.final = {
      {self}
    }
  end
}
local factory = Component.createFactory(blueprint)
local props = {
  group = group
}
local component = factory.create(props)

local dt = 1
group.updateAll(dt)
group.drawAll()

group.delete(component)
group.updateAll(dt)

assert(#calls.init == 1)
assert(calls.init[1][1] == props)

assert(#calls.update == 1)
assert(calls.update[1][1] == props)
assert(calls.update[1][2] == dt)

assert(#calls.draw == 1)
assert(calls.draw[1][1] == props)

assert(#calls.final == 1)
assert(calls.final[1][1] == props)
