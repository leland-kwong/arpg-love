local config = require 'config'
local messageBus = require 'utils.message-bus'

local M = messageBus.new()

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
M.PLAYER_HIT_RECEIVED = 'PLAYER_HIT_RECEIVED'
M.PLAYER_ATTACK = 'PLAYER_ATTACK'
M.PLAYER_LEVEL_UP = 'PLAYER_LEVEL_UP'
M.PLAYER_STATS_NEW_MODIFIERS = 'PLAYER_STATS_NEW_MODIFIERS'
M.SET_TEXT_INPUT = 'SET_TEXT_INPUT'
M.GUI_TEXT_INPUT = 'GUI_TEXT_INPUT'

M.GENERATE_LOOT = 'GENERATE_LOOT'
--[[
  {
    posX,
    posY,
    item
  }
]]

M.ENEMY_DESTROYED = 'ENEMY_DESTROYED'

M.ITEM_HOVERED = 'ITEM_HOVERED'
M.ITEM_PICKUP = 'ITEM_PICKUP'
M.ITEM_PICKUP_SUCCESS = 'ITEM_PICKUP_SUCCESS'
M.ITEM_PICKUP_CANCEL = 'ITEM_PICKUP_CANCEL'
M.DROP_ITEM_ON_FLOOR = 'DROP_ITEM_ON_FLOOR'
M.INVENTORY_PICKUP = 'INVENTORY_PICKUP'
M.INVENTORY_DROP = 'INVENTORY_DROP'
-- when clicked outside of the screen, we drop the item on the floor
M.INVENTORY_DROP_MODE_FLOOR = 'INVENTORY_DROP_MODE_FLOOR'
M.INVENTORY_DROP_MODE_INVENTORY = 'INVENTORY_DROP_MODE_INVENTORY'

M.EQUIPMENT_SWAP = 'EQUIPMENT_SWAP'
M.EQUIPMENT_CHANGE = 'EQUIPMENT_CHANGE'
M.EQUIPMENT_UNEQUIP = 'EQUIPMENT_UNEQUIP'

M.PLAYER_HEAL_SOURCE_ADD = 'PLAYER_HEAL_SOURCE_ADD'
--[[
  {
    amount = NUMBER,
    source = STRING,
    duration = NUMBER
  }
]]

M.PLAYER_HEAL_SOURCE_REMOVE = 'PLAYER_HEAL_SOURCE_REMOVE'
--[[
  {
    source = STRING
  }
]]

return M