local function callableObject(props)
  assert(
    type(props.__call) == 'function' or type(props.value) ~= nil,
    '`__call` or `value` property must be provided'
  )
  props.__call = props.__call or function()
    return props.value
  end
  props.__index = props
  return setmetatable(props, props)
end

return callableObject