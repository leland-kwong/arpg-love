local aiTypesPath = 'components.ai.types.'
local Enum = require 'utils.enum'
local F = require 'utils.functional'

local files = F.filter(
  love.filesystem.getDirectoryItems('components/ai/types'),
  function(file)
    return file ~= 'init.lua'
  end
)

local typeDefs = F.reduce(
  F.filter(
    F.map(files, function(key)
      local key = string.sub(key, 1, -5)
      local definition = require(aiTypesPath..key)
      assert(definition._isAi, 'ai definitions must be created using `create-blueprint`')
      return definition
    end),
    function(item)
      return not item.legendary and item.baseProps
    end
  ),
  function(defs, item)
    defs[item.baseProps.type] = item
    return defs
  end,
  {}
)

local typeNames = F.reduce(F.keys(typeDefs), function(names, key)
  names[key] = key
  return names
end, {})

return {
  types = typeNames,
  typeDefs = typeDefs
}