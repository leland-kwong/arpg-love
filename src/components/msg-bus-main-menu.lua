local MessageBus = require 'utils.message-bus'
local config = require 'config'

local M = MessageBus.new()

if config.isDebug then
  local proxy = {}
  setmetatable(M, {
    --[[
      If property doesn't exist, throw an error. This is to alert us about accessing properties that don't
      exist. The main use case is when trying to access message type constants, ie `msgBus.PLAYER_HEAL_SOURCE_ADD` should not be a `nil` value.
    ]]
    __index = function(_, name)
      if not proxy[name] then
        error('[msgBus] property `'..name..'` not defined')
      end
      return proxy[name]
    end,
    __newindex = function(_, name, value)
      proxy[name] = value
    end
  })
end

M.TOGGLE_MAIN_MENU = 'TOGGLE_MAIN_MENU'

return M