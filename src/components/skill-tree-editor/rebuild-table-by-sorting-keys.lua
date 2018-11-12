--[[
  Makes a new copy of a table by setting properties based on sorted key order. This is necessary
  to guarantee that serialization/deserialization are identical, otherwise theres no guarantee on
  the order of the key serialization.
]]
local function rebuildTableBySortingKeys(val)
  if type(val) ~= 'table' then
    return val
  end

  local newTable = {}
  local keys = {}
  for k in pairs(val) do
    table.insert(keys, k)
  end
  table.sort(keys)

  for i=1, #keys do
    local key = keys[i]
    newTable[key] = rebuildTableBySortingKeys(val[key])
  end

  return newTable
end

return rebuildTableBySortingKeys