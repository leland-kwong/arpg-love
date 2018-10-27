local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local previousState = previousState or {}
local previousEntityIds = {}

local function getComponentStats()
  print('\n\n')
  local nextState = {}
  local nextEntityIds = {}
  for group in pairs(Component.groups) do
    local count = 0
    for id in pairs(Component.groups[group].getAll()) do
      count = count + 1
      nextEntityIds[id] = true
    end
    nextState[group] = count
    local diff = count - (previousState[group] or 0)

    if diff > 0 then
      print(group..': '..count..' '..diff)
      for id,entity in pairs(Component.groups[group].getAll()) do
        if (not previousEntityIds[id]) then
          for k,v in pairs(entity) do
            if type(v) ~= 'function' then
              print(k, v)
            end
          end
        end
      end
    end
  end
  previousState = nextState
  previousEntityIds = nextEntityIds
end

msgBus.on('NEW_MAP', getComponentStats)
