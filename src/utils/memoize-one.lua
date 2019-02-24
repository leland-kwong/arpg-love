return function(callback)
  local prevArg
  local prevVal
  return function(a)
    if prevArg == a then
      return prevVal
    end
    local result = callback(a)
    prevArg = a
    prevVal = result
    return result
  end
end