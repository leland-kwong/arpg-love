local function validateProps(props)
  assert(props.type == 'string')
end

local statDefaults = {
  armor = 100,
  moveSpeed = 100,
  sightRadius = 14,
  freelyMove = 0,
  experience = 1, -- amount of experience the ai grants when destroyed

  freeze = 0
}
statDefaults.__index = statDefaults

return function(definition)
  local oCreate = definition.create
  setmetatable(definition.baseProps, statDefaults)
  definition._isAi = true
  definition.create = function()
    local instance = oCreate()
    instance.__index = definition.baseProps
    return setmetatable(instance, instance)
  end
  return definition
end