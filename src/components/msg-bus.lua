local config = require 'config'
local messageBus = require 'utils.message-bus'

local M = messageBus.new()

if config.isDebug then
  local proxy = {}
  setmetatable(M, {
    --[[
      If property doesn't exist, throw an error. This is to alert us about accessing properties that don't
      exist. The main use case is when trying to access message type constants, ie `msgBus.PLAYER_ADD_HEAL_SOURCE` should not be a `nil` value.
    ]]
    __index = function(_, name)
      if not proxy[name] then
        error('[msgBus] property `'..name..'` not found')
      end
      return proxy[name]
    end,
    __newindex = function(_, name, value)
      proxy[name] = value
    end
  })
end

M.GAME_LOADED = 'GAME_LOADED'
M.KEY_PRESSED = 'KEY_PRESSED'
M.KEY_RELEASED = 'KEY_RELEASED'
M.MOUSE_PRESSED = 'MOUSE_PRESSED'
M.MOUSE_RELEASED = 'MOUSE_RELEASED'
M.MOUSE_WHEEL_MOVED = 'MOUSE_WHEEL_MOVED'
M.WINDOW_FOCUS = 'WINDOW_FOCUS'
M.NEW_FLOWFIELD = 'NEW_FLOWFIELD'
M.CHARACTER_HIT = 'CHARACTER_HIT'
M.EXPERIENCE_GAIN = 'EXPERIENCE_GAIN'
M.PLAYER_HIT = 'PLAYER_HIT'
M.PLAYER_LEVEL_UP = 'PLAYER_LEVEL_UP'
M.SET_TEXT_INPUT = 'SET_TEXT_INPUT'
M.GUI_TEXT_INPUT = 'GUI_TEXT_INPUT'
M.GUI_NODE_CLEANUP = 'GUI_NODE_CLEANUP'
M.EQUIPMENT_SWAP = 'EQUIPMENT_SWAP'
M.GENERATE_LOOT = 'GENERATE_LOOT'
M.ITEM_HOVERED = 'ITEM_HOVERED'
M.DROP_ITEM_ON_FLOOR = 'DROP_ITEM_ON_FLOOR'
M.INVENTORY_PICKUP = 'INVENTORY_PICKUP'
M.INVENTORY_DROP = 'INVENTORY_DROP'
M.INVENTORY_DROP_MODE_FLOOR = 'INVENTORY_DROP_MODE_FLOOR'
M.INVENTORY_DROP_MODE_INVENTORY = 'INVENTORY_DROP_MODE_INVENTORY'

return M