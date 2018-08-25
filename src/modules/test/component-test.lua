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

-- new test group
local blueprint2 = {
  group = group
}
local factory = Component.createFactory(blueprint2)
local c1 = factory.create()
local c2 = factory.create():setParent(c1)
c1:delete(true)
--[[
  run an update since parented components won't clean themselves up until
  the next frame
]]
group.updateAll(dt)
assert(c2:isDeleted(), 'child object should be deleted')

local testUniqueIds = (function()
  -- [[ test unique ids ]]
  local foobarFactory = Component.createFactory({
    group = group,
    id = 'foobar'
  })
  local foobar1 = foobarFactory.create()
  local foobar2 = foobarFactory.create()
  assert(foobar1:isDeleted(), 'first unique instance should be deleted since it has a duplicated id')
  assert(Component.get('foobar') ~= nil, 'failed to find by component by id')
end)()