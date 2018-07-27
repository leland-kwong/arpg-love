local Component = require 'modules.component'

local group = Component.newGroup()
local calls = {}

local blueprint = {
  getInitialProps = function()
    local props = {
      x = 0,
      y = 0,
      foo = 'foo',
    }
    calls.initialProps = {
      {props}
    }
    return props
  end,

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
local factory = group.createFactory(blueprint)
local component = factory:create()

local dt = 1
group.updateAll(dt)
group.drawAll()

component:delete()
group.updateAll(dt)

assert(#calls.initialProps == 1)
assert(type(calls.initialProps[1][1]) == 'table')

local initialProps = calls.initialProps[1][1]
assert(#calls.init == 1)
assert(calls.init[1][1] == initialProps)

assert(#calls.update == 1)
assert(calls.update[1][1] == initialProps)
assert(calls.update[1][2] == dt)

assert(#calls.draw == 1)
assert(calls.draw[1][1] == initialProps)

assert(#calls.final == 1)
assert(calls.final[1][1] == initialProps)