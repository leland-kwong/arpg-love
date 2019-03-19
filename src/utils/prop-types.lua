local deepCopy = require 'utils.object-utils'.deepCopy

local function setupAndValidateProps(c, types)
  for k,v in pairs(types) do
    c[k] = deepCopy(c[k] or v)
    local isValid = type(c[k]) == type(v)
    assert(isValid, 'invalid property `'..k..'`')
  end
  return c
end

return setupAndValidateProps