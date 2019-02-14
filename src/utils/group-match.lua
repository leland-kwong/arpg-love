--[[
  Checks if a list of words (space-delimited) contains at least one word from another list
]]

local parsedCache = {}

local function buildGroup(groupString)
  local F = require 'utils.functional'
  local String = require 'utils.string'
  local trimmed = String.trim(groupString)
  local split = String.split(trimmed, ' ')
  return {
    hash = F.reduce(split, function(map, item)
      map[item] = true
      return map
    end, {}),
    list = split,
    length = #split,
    type = 'parsedGroup'
  }
end

local parseGroup = function(groupString)
  local parsed = parsedCache[groupString]
  if (not parsed) then
    parsed = buildGroup(groupString)
    parsedCache[groupString] = parsed
  end
  return parsed
end

local function groupMatch(groupA, groupB)
  assert(type(groupA) == 'string', 'group to check must be a string')

  local hasMatch = groupA == groupB

  if hasMatch then
    return true
  end

  local isMultiGroup = type(groupB) == 'table'
  if isMultiGroup then
    local multiGroup = groupB
    local i=1
    while (not hasMatch) and i <= #multiGroup do
      hasMatch = groupMatch(groupA, multiGroup[i])
      i = i + 1
    end
    return hasMatch
  end

  local hashA = parseGroup(groupA).hash
  local parsedB = parseGroup(groupB)
  local i = 1
  while (not hasMatch) and (i <= parsedB.length) do
    local itemB = parsedB.list[i]
    hasMatch = hashA[itemB] ~= nil
    i = i + 1
  end
  return hasMatch
end

return groupMatch