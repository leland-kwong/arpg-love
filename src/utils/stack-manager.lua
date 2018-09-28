-- stack manager

local M = {}

function M.new(initialStack)
  local manager = setmetatable(
    initialStack or {},
    M
  )
  M.__index = M
  return manager
end

function M:push(item)
  table.insert(self, item)
  return self
end

function M:pop()
  -- remove most recently pushed
  table.remove(self, #self)
  -- return the previous item
  return self[#self]
end

-- clears the entire item stack and adds the current scene
-- to the top of the stack
function M:clear()
  for i=1, #self do
    self[i] = nil
  end
  return self
end

function M:canPop()
  return (#self - 1) > 0
end

return M