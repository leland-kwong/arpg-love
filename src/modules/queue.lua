local noop = require 'utils.noop'
local assign = require 'utils.object-utils'.assign

local Q = {}

local defaultOptions = {
  development = false,
  context = '',
  beforeFlush = noop,
}

function Q:new(options)
  options = assign({}, defaultOptions, options)

  local queue = {
    list = {}, -- list of calls grouped by their order
    orders = {}, -- list of orders (priority)
    length = 0, -- num of calls added to the queue
    beforeFlush = options.beforeFlush,
    development = options.development,
    context = options.context
  }
  setmetatable(queue, self)
  self.__index = self
  return queue
end

-- insert callback with 1 argument
function Q:add(order, cb, a)
  -- ignore empty callbacks
  if (not cb) then
    return
  end

  assert(type(order) == 'number', 'order must be an integer')

  local list = self.list[order]
  local isNewOrder = not list
  if isNewOrder then
    list = {}
    self.list[order] = list
    table.insert(self.orders, order)
  end

  local itemIndex = self.length + 1
  local item = {cb, a}

  list[#list + 1] = item
  self.length = self.length + 1
  return self
end

-- iterate callbacks by `order` and clears the queue
function Q:flush()
  self:beforeFlush()
  local list = self.list
  local orders = self.orders
  table.sort(orders)

  -- create new lists before flushing since during flushing there may be new callbacks being added
  self.list = {}
  self.orders = {}

  for i=1, #orders do
    local order = orders[i]
    local row = list[order]
    for j=1, #row do
      local item = row[j]
      item[1](item[2])
    end
  end

  self.length = 0
  return self
end

function Q:getStats()
  return self.minOrder, self.maxOrder, self.length
end

return Q