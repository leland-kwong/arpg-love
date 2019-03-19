local TablePool = {}

function TablePool.new(createFn)
  local pool = {}

  function pool.get(id)
    local tbl = pool[id]
    if not tbl then
      tbl = createFn and createFn() or {}
      pool[id] = tbl
    end
    return tbl
  end

  return pool
end

-- an auto pool that returns an obj if one has been released, otherwise returns a new one
function TablePool.newAuto(clearFn)
  local pool = {}

  function pool.get()
    local obj = pool[#pool]
    if not obj then
      return {}
    end
    -- remove from pool
    pool[#pool] = nil
    if clearFn then
      clearFn(obj)
    end
    return obj
  end

  function pool.release(obj)
    pool[#pool + 1] = obj
  end

  return pool
end

return TablePool