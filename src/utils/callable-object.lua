local function callableObject(props)
  assert(
    type(props.__call) == 'function' or type(props.value) ~= nil,
    '`__call` or `value` property must be provided'
  )
  return setmetatable(props, {
    __call = props.__call or function()
      return props.value
    end
  })
end

return callableObject