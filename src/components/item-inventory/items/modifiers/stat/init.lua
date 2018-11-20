local itemSystem = require 'components.item-inventory.items.item-system'
local msgBus = require 'components.msg-bus'
local extend = require 'utils.object-utils'.extend
local fancyRandom = require 'utils.fancy-random'
local Color = require 'modules.color'
local modDefinitions = require 'components.item-inventory.modifier-definitions'

local function calcValue(k, v)
  return modDefinitions[k].range(v)
end

local module = itemSystem.registerModule({
  name = 'stat',
  type = itemSystem.moduleTypes.MODIFIERS,
  active = function(_, props, state)
    msgBus.on(msgBus.PLAYER_UPDATE_START, function()
      if (not state.equipped) then
        return msgBus.CLEANUP
      end
      for k,v in pairs(props) do
        local Component = require 'modules.component'
        Component.get('PLAYER').stats:add(k, calcValue(k, v))
      end
    end, 1)
  end,
  tooltip = function(_, props)
    local calculatedProps = {}
    for k,v in pairs(props) do
      calculatedProps[k] = calcValue(k, v)
    end
    return {
      type = 'statsList',
      data = calculatedProps
    }
  end
})

--[[
  modifiers may be passed in as actual values or ranges. If a range is provided, then it will be
  converted to a single value with a randomizer
]]
return function(props)
  return module(props)
end