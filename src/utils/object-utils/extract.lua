return function(obj, ...)
  local values = {...}
  -- set each output value to they input object's value
  for i=1, #values do
    local key = values[i]
    values[i] = obj[key]
  end
  return unpack(values)
end