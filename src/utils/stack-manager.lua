-- stack manager

local M = {}

function M.new(initialStack)
  local manager = setmetatable({
    stack = initialStack or {}
  }, M)
  M.__index = M
  return manager
end

function M:push(item)
  table.insert(self.stack, item)
  return self
end

function M:pop()
  local previousItem = self.stack[#self.stack - 1]
  -- remove most recently pushed
  table.remove(self.stack, #self.stack)
  -- return the previous item
  return previousItem
end

-- clears the entire item stack
function M:clear()
  self.stack = {}
  return self
end

function M:canPop()
  return (#self.stack - 1) > 0
end

-- returns the last item in the stack
function M:getLastItem()
  return self.stack[#self.stack]
end

function M:popAll()
  local stack = self.stack
  self:clear()
  return stack
end

return M