local Q = require 'modules.queue'

local queue = Q:new()

local calls = {}
queue:add(2, function()
  table.insert(calls, 2)
end)

queue:add(1, function()
  table.insert(calls, 1)
end)

queue:flush()

assert(#calls == 2, 'should be equal to number of items in queue')
assert(
  calls[1] == 1
  and calls[2] == 2,

  'should be called based on `order` value'
)

assert(queue.length == 0, 'queue should be empty')
