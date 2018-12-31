local MessageBus = require 'utils.message-bus'
local config = require 'config.config'

local M = MessageBus.new()

if config.isDevelopment then
  local proxy = {}
  setmetatable(M, {
    --[[
      If property doesn't exist, throw an error. This is to alert us about accessing properties that don't
      exist. The main use case is when trying to access message type constants, ie `msgBus.PLAYER_HEAL_SOURCE_ADD` should not be a `nil` value.
    ]]
    __index = function(_, name)
      return name
    end
  })
end

M.TOGGLE_MAIN_MENU = 'TOGGLE_MAIN_MENU'

M.MENU_ITEM_ADD = 'MENU_ITEM_ADD'
M.MENU_ITEM_REMOVE = 'MENU_ITEM_REMOVE'

return M