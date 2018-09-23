local callableObject = require 'utils.callable-object'

local function setupChanceFunctions(types)
  local list = {}
  for i=1, #types do
    local props = types[i]
    assert(type(props.chance) == 'number', 'chance must be a number')
    local t = callableObject(props)
    for j=1, t.chance do
      table.insert(list, t)
    end
  end
  return function(a, b, c, d, e, f)
    local index = math.random(1, #list)
    return list[index](a, b, c, d, e, f)
  end
end

return setupChanceFunctions