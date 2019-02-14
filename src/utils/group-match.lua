--[[
  Checks if a list of words (space-delimited) contains at least one word from another list
]]

local F = require 'utils.functional'
local String = require 'utils.string'

local parsedCache = {}

local function buildGroup(groupString)
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

local function check(groupA, groupB)
  local hashA = parseGroup(groupA).hash
  local parsedB = parseGroup(groupB)
  for i=1, parsedB.length do
    local itemB = parsedB.list[i]
    local hasMatch = hashA[itemB] ~= nil
    if hasMatch then
      return true
    end
  end
  return false
end

local function groupMatch(groupA, groupB)
  assert(type(groupA) == 'string', 'group to check must be a string')

  local hasMatch = groupA == groupB

  if hasMatch then
    return true
  end

  local isMultiGroup = type(groupB) == 'table'
  if isMultiGroup then
    for i=1, #groupB do
      if check(groupA, groupB[i]) then
        return true
      end
    end
    return false
  end

  return check(groupA, groupB)
end

return groupMatch