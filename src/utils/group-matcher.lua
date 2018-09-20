local primes = {
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199
}

local function GroupMatcher(groupNames)
  local groupByGroupId = {}
  local Matcher = {}
  local valueByName = {}

  setmetatable(valueByName, {
    __index = function(t, k)
      return 1
    end
  })
  for i=1, #groupNames do
    local name = groupNames[i]
    local v = primes[i]
    valueByName[name] = v
    Matcher[name] = name
  end

  function Matcher.create(a, b, c, d, e, f, g)
    local groupId =
        valueByName[a]
      * valueByName[b]
      * valueByName[c]
      * valueByName[d]
      * valueByName[e]
      * valueByName[f]
      * valueByName[g]
    local groupById = groupByGroupId[groupId]
    if (not groupById) then
      local items = {a, b, c, d, e, f, g}
      groupById = {}
      for i=1, #items do
        local v = items[i]
        if v then
          groupById[v] = true
        end
      end
      groupByGroupId[groupId] = groupById
    end
    return groupById
  end

  -- checks if a group contains the given string
  function Matcher.contains(string, group)
    for k in pairs(group) do
      if string == k then
        return true
      end
    end
    return false
  end

  -- checks if at least one value in groupA exists in groupB
  function Matcher.matches(groupA, groupB)
    local typeA, typeB = type(groupA), type(groupB)

    if (typeA == 'string' and typeB == 'string') then
      return groupA == groupB
    end

    if (typeA == 'string') then
      return Matcher.contains(groupA, groupB)
    end

    if (typeB == 'string') then
      return Matcher.contains(groupB, groupA)
    end

    for k in pairs(groupA) do
      if groupB[k] then
        return true
      end
    end
    return false
  end

  return Matcher
end

return GroupMatcher