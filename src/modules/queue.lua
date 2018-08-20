local perf = require 'utils.perf'
local typeCheck = require 'utils.type-check'

local Q = {}

function Q:new(options)
  options = options or { development = false }
  local queue = {
    list = {},
    length = 0,
    minOrder = 0,
    maxOrder = 0, -- highest order that has been added to the queue
    development = options.development
  }
  setmetatable(queue, self)
  self.__index = self
  return queue
end

local itemPool = {}
local NUMBER = 'number'
local orderError = function(order)
  local valid = type(order) == NUMBER
    and order > 0
    and order % 1 == 0 -- must be integer
  if valid then return true end
  return false, 'order must be greater than 0 and an integer, received `'..tostring(order)..'`'
end
local max, min = math.max, math.min

-- insert callback with maximum 2 arguments
function Q:add(order, cb, a, b)
  local isNewQueue = self.length == 0
  if isNewQueue then
    self.minOrder = order
    self.maxOrder = order
  end

  if self.development then
    typeCheck.validate(
      order,
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
  self.minOrder = min(self.minOrder, order)
  self.maxOrder = max(self.maxOrder, order)
  return self
end

-- iterate callbacks by `order` and clears the queue
function Q:flush()
  for i=self.minOrder, self.maxOrder do
    local row = self.list[i]
    local rowLen = row and #row or 0
    if rowLen > 0 then
      for j=1, rowLen do
        local item = row[j]
        -- execute callback
        item[1](item[2], item[3])
        -- clear item from queue
        row[j] = nil
      end
    end
  end
  self.length = 0
  return self
end

function Q:getStats()
  return self.minOrder, self.maxOrder, self.length
end

return Q