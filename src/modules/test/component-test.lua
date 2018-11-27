local Component = require 'modules.component'

local Test = {
  tests = {}
}

function Test.suite(name, fn)
  table.insert(Test.tests, {name, fn})
end

function Test.run()
  local tests = Test.tests
  for i=1, #tests do
    local name, testFn = unpack(tests[i])
    print('test '..name)
    testFn()
  end
end

local group = Component.newGroup({ name = 'test-group' })
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

component:delete()
group.updateAll(dt)

assert(#calls.init == 1)
assert(calls.init[1][1].initialProps == props)

assert(#calls.update == 1)
assert(calls.update[1][1].initialProps == props)
assert(calls.update[1][2] == dt)

assert(#calls.draw == 1)
assert(calls.draw[1][1].initialProps == props)

assert(#calls.final == 1)
assert(calls.final[1][1].initialProps == props)

Test.suite('recursiveDeleteTest', function()
  -- new test group
  local blueprint2 = {
    group = group
  }
  local factory = Component.createFactory(blueprint2)
  local c1 = factory.create()
  local c2 = factory.create():setParent(c1)
  c1:delete(true)
  assert(c2:isDeleted(), 'child object should be deleted')
end)

Test.suite('nonRecursiveDeleteTest', function()
  local blueprint2 = {
    group = group
  }
  local factory = Component.createFactory(blueprint2)
  local c1 = factory.create()
  local c2 = factory.create():setParent(c1)
  c1:delete()
  assert(not c2:isDeleted(), 'non-recursive deletes should not delete their children')
end)

Test.suite('testUniqueIds', function()
  -- [[ test unique ids ]]
  local foobarFactory = Component.createFactory({
    group = group,
    id = 'foobar'
  })
  local foobar1 = foobarFactory.create()
  assert(Component.get('foobar') ~= nil, 'failed to find by component by id')
end)

Test.suite('duplicateIds', function()
  local foo1 = Component.create({
    id = 'foo'
  })

  local foo2 = Component.create({
    id = 'foo'
  })

  assert(foo1:isDeleted(), 'components with duplicate ids should have the first instance deleted')
end)

Test.run()