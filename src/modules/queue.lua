local perf = require 'utils.perf'

local Q = {}

function Q:new(options)
  options = options or { development = false }
  local queue = {
    list = {},
    length = 0,
    maxOrder = 0,
    development = options.development
  }
  setmetatable(queue, self)
  self.__index = self
  return queue
end

local itemPool = {}
local NUMBER = 'number'
local orderError = 'order must be greater than 0 and an integer'
local max = math.max
-- insert callback
function Q:add(order, cb, a, b)
  if self.development then
    assert(
      type(order) == NUMBER
        and order > 0
        and order % 1 == 0, -- must be integer
      orderError
    )
  end

  local list = self.list[order]
  if not list then
    list = {}
    self.list[order] = list
  end

  local itemIndex = self.length + 1
  local item = itemPool[itemIndex]
  if not item then
    item = {}
    itemPool[itemIndex] = item
  end

  item[1] = cb
  item[2] = a
  item[3] = b

  list[#list + 1] = item
  self.length = self.length + 1
  self.maxOrder = max(self.maxOrder, order)
end

-- iterate callbacks by `order` and clears the queue
function Q:flush()
  for i=1, self.maxOrder do
    local row = self.list[i]
    if row and #row > 0 then
      for j=1, #row do
        local item = row[j]
        -- execute callback
        item[1](item[2], item[3])
        -- clear item from queue
        row[j] = nil
      end
    end
  end
  self.length = 0
  self.maxOrder = 0
end

return Q