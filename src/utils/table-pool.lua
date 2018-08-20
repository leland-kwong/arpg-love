local TablePool = {}

function TablePool.new()
  local pool = {}

  function pool.get(id)
    local tbl = pool[id]
    if not tbl then
      tbl = {}
      pool[id] = tbl
    end
    return tbl
  end

  return pool
end

return TablePool