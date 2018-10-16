--[[
  adds a `set` method to the object so that we can do chained setting
  and return the object all in one go.
]]

local function set(self, prop, value)
  self[prop] = value
  return self
end

local function setWithUndefinedCheck(self, prop, value)
  local isUndefinedProp = self[prop] == nil
  if isUndefinedProp then
    error('property '..prop..' is not defined')
  end
  self[prop] = value
  return self
end

local function setProp(obj, isDevelopment)
  obj.set = isDevelopment and setWithUndefinedCheck or set
  return obj
end

return setProp