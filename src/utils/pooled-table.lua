local function pooledTable(callback)
  local output = {}
  return function(a, b, c, d, e, f)
    output = callback(output, a, b, c, d , e, f) or output
    return output
  end
end

return pooledTable