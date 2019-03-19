--[[
  adds a `set` method to the object so that we can do chained setting
  and return the object all in one go.
]]

local function set(self, prop, value)
  self[prop] = value
  return self
end

local function setProp(obj)
  obj.set = set
  return obj
end

return setProp