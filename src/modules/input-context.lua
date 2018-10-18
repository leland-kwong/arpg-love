local Lru = require 'utils.lru'
local InputContext = {}


local parseStringCache = Lru.new(500)

local function parseString(str)
  local strings = parseStringCache.get(str)
  if (not strings) then
    stringsToMatch = {}
    for v in string.gmatch(str, "%S+") do
      stringsToMatch[v] = true
    end
    parseStringCache:set(str, stringsToMatch)
  end
  return stringsToMatch
end

local activeContext = nil

function InputContext.set(contextName)
  local isNewContext = activeContext ~= contextName
  if (not isNewContext) then
    return
  end
  assert(type(contextName) == 'string', 'contextName must be a string')
  assert(not string.find(contextName, ' '), 'contextName must not contain spaces')
  activeContext = contextName
end

-- supports a space separated list of context names to match against
function InputContext.contains(contextName)
  return parseString(contextName)[activeContext]
end

function InputContext.get()
  return activeContext
end

return InputContext