local Stats = {}
Stats.__index = Stats

--[[
  functional stats are calculated at the end but do not affect the base stats
]]

local readOnlyMt = {
  __newindex = function()
    error('read only')
  end
}

local EMPTY = setmetatable({}, readOnlyMt)

local methods = {}

function methods.add(self, prop, value, context)
  local isFunction = type(value) == 'function'
  if isFunction then
    self.functionalStats[prop] = self.functionalStats[prop] or {}
    table.insert(self.functionalStats[prop], value)
  else
    self[prop] = self[prop] + value
  end
  self.hasChanges = true
  return self
end

-- returns the fully calculated property
function methods.get(self, prop)
  local fStats = self.functionalStats[prop] or EMPTY
  local mTotal = 0 -- modifier total
  local baseValue = self[prop]
  for i=1, #fStats do
    mTotal = mTotal + fStats[i](self)
  end
  return baseValue + mTotal
end

local statsMt = {
  __index = function(self, k)
    return methods[k] or self.baseStats[k] or 0
  end
}

function Stats.new(self, baseStats)
  return setmetatable({
    baseStats = baseStats or EMPTY,
    functionalStats = {},
    hasChanges = false
  }, statsMt)
end

function Stats.is(value)
  return getmetatable(value) == Stats
end

return Stats