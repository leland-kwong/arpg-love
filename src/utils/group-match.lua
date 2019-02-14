--[[
  Checks if a list of words (space-delimited) contains at least one word from another list
]]

local F = require 'utils.functional'
local String = require 'utils.string'

local parsedCache = {}

local function validateGroup(groupHash, allowedLabels)
  for label in pairs(groupHash) do
    if (not allowedLabels[label]) then
      local names = table.concat(F.keys(allowedLabels), ', ')
      error('Invalid group label `'..label..'`. Allowed values are one of ['..names..']')
    end
  end
end

local function buildGroup(groupString, allowedLabels)
  local trimmed = String.trim(groupString)
  local split = String.split(trimmed, ' ')
  local hash = F.reduce(split, function(map, item)
    map[item] = true
    return map
  end, {})

  -- validate group
  if allowedLabels then
    validateGroup(hash, allowedLabels)
  end

  return {
    hash = hash,
    list = split,
    length = #split
  }
end

local parseGroup = function(groupString, allowedLabels)
  local parsed = parsedCache[groupString]
  if (not parsed) then
    parsed = buildGroup(groupString, allowedLabels)
    parsedCache[groupString] = parsed
  end
  return parsed
end

local function check(groupA, groupB, allowedLabels)
  local hashA = parseGroup(groupA, allowedLabels).hash
  local parsedB = parseGroup(groupB, allowedLabels)
  for i=1, parsedB.length do
    local itemB = parsedB.list[i]
    local hasMatch = hashA[itemB] ~= nil
    if hasMatch then
      return true
    end
  end
  return false
end

local function groupMatch(groupA, groupB, allowedLabels)
  assert(type(groupA) == 'string', 'group to check must be a string')

  local hasMatch = groupA == groupB

  if hasMatch then
    return true
  end

  local isMultiGroup = type(groupB) == 'table'
  if isMultiGroup then
    for i=1, #groupB do
      if check(groupA, groupB[i], allowedLabels) then
        return true
      end
    end
    return false
  end

  return check(groupA, groupB, allowedLabels)
end

return groupMatch