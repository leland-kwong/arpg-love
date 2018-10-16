local perf = require 'utils.perf'
local typeCheck = require 'utils.type-check'
local noop = require 'utils.noop'
local assign = require 'utils.object-utils'.assign

local Q = {}

local defaultOptions = {
  development = false,
}

function Q:new(options)
  options = assign({}, defaultOptions, options)
  local queue = {
    list = nil, -- list of calls grouped by their order
    orders = nil, -- list of orders (priority)
    length = 0, -- num of calls added to the queue
    development = options.development,
    beforeFlush = noop,
    ready = true
  }
  setmetatable(queue, self)
  self.__index = self
  return queue
end

local orderError = function(order)
  local valid = type(order) == 'number'
    and order > 0
    and order % 1 == 0 -- must be integer
  if valid then return true end
  return false, 'order must be greater than 0 and an integer, received `'..tostring(order)..'`'
end
local max, min = math.max, math.min

-- insert callback with maximum 2 arguments
function Q:add(order, cb, a, b, c)
  local isNewQueue = not self.list
  if isNewQueue then
    self.list = {}
    self.orders = {}
  end

  if self.development then
    typeCheck.validate(
      order,
      orderError
    )
  end

  local list = self.list[order]
  local isNewOrder = not list
  if isNewOrder then
    list = {}
    self.list[order] = list
    table.insert(self.orders, order)
  end

  local itemIndex = self.length + 1
  local item = {cb, a, b, c}

  list[#list + 1] = item
  self.length = self.length + 1
  return self
end

-- iterate callbacks by `order` and clears the queue
local emptyList = {}
function Q:flush()
  self:beforeFlush()
  local list = self.list or emptyList
  local orders = self.orders or emptyList
  table.sort(orders)
  self.list = nil
  self.orders = nil
  for i=1, #orders do
    local order = orders[i]
    local row = list[order]
    local rowLen = row and #row or 0
    for j=1, rowLen do
      local item = row[j]
      item[1](item[2], item[3], item[4])
    end
  end
  self.length = 0
  return self
end

function Q:onBeforeFlush(fn)
  self.beforeFlush = fn
end

function Q:getStats()
  return self.minOrder, self.maxOrder, self.length
end

return Q