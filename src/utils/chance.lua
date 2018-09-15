local function CallableObject(props)
  assert(type(props.__call) == 'function', '__call property must be a function')
  return setmetatable(props, {
    __call = props.__call
  })
end

local function setupChanceFunctions(types)
  local list = {}
  for i=1, #types do
    local t = CallableObject(types[i])
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