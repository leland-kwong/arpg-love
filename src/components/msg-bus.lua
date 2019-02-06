local MessageBus = require 'utils.message-bus'

local M = MessageBus.new()

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

M.GAME_LOADED = 'GAME_LOADED'
M.GAME_UNLOADED = 'GAME_UNLOADED'
M.NEW_GAME = 'NEW_GAME' -- this will be used whenever we exit the currently loaded game. Currently its being unused
M.SET_CONFIG = 'SET_CONFIG' -- makes updates to the game config

M.KEY_DOWN = 'KEY_DOWN'
M.KEY_RELEASED = 'KEY_RELEASED'
M.KEY_PRESSED = 'KEY_PRESSED'

M.MOUSE_PRESSED = 'MOUSE_PRESSED'
M.MOUSE_RELEASED = 'MOUSE_RELEASED'
M.MOUSE_WHEEL_MOVED = 'MOUSE_WHEEL_MOVED'

M.WINDOW_FOCUS = 'WINDOW_FOCUS'
M.CHARACTER_HIT = 'CHARACTER_HIT'
--[[
  {
    parent = TABLE, -- component instance
    damage = NUMBER,
    lightningDamage = NUMBER,
    criticalChance = NUMBER, -- percentage value multiplier where 0.25 means 25%
    criticalMultiplier = NUMBER, -- percentage value multplier where 0.25 means 25%
    duration = NUMBER, -- duration in seconds
    modifiers = TABLE, -- key-value hash of properties
    statusIcon = STRING,
    source = STRING, -- multiple sources of the same type will get reapplied instead of stacked

    shockStatus = NUMBER, -- amount enemy is shocked
    fireStatus = NUMBER,
    coldStatus = NUMBER
  }
]]

M.EXPERIENCE_GAIN = 'EXPERIENCE_GAIN'
M.PLAYER_ACTION_ERROR = 'PLAYER_ACTION_ERROR' --[[ STRING ]]
M.PLAYER_HIT_RECEIVED = 'PLAYER_HIT_RECEIVED'
M.PLAYER_WEAPON_MUZZLE_FLASH = 'PLAYER_WEAPON_MUZZLE_FLASH'
M.PLAYER_WEAPON_ATTACK = 'PLAYER_WEAPON_ATTACK'
M.PLAYER_LEVEL_UP = 'PLAYER_LEVEL_UP'
M.PLAYER_STATS_NEW_MODIFIERS = 'PLAYER_STATS_NEW_MODIFIERS'
M.PLAYER_PORTAL_OPEN = 'PLAYER_PORTAL_OPEN'
M.PORTAL_ENTER = 'PORTAL_ENTER'
M.SET_TEXT_INPUT = 'SET_TEXT_INPUT'
M.GUI_TEXT_INPUT = 'GUI_TEXT_INPUT'

M.SCENE_STACK_PUSH = 'SCENE_STACK_PUSH'
M.SCENE_STACK_POP = 'SCENE_STACK_POP'
M.SCENE_STACK_REPLACE = 'SCENE_STACK_REPLACE'
M.SCENE_CHANGE = 'SCENE_CHANGE' -- triggers on SCENE_STACK_PUSH and SCENE_STACK_POP

M.GENERATE_LOOT = 'GENERATE_LOOT'
--[[
  {
    posX,
    posY,
    item
  }
]]

M.ENEMY_DESTROYED = 'ENEMY_DESTROYED'

M.ITEM_EQUIPPED = 'ITEM_EQUIPPED'
M.ITEM_UPGRADE_UNLOCKED = 'ITEM_UPGRADE_UNLOCKED'
M.ITEM_HOVERED = 'ITEM_HOVERED'
M.ITEM_PICKUP = 'ITEM_PICKUP' --[[ itemInstance ]]
M.ITEM_PICKUP_CANCEL = 'ITEM_PICKUP_CANCEL'
M.DROP_ITEM_ON_FLOOR = 'DROP_ITEM_ON_FLOOR'
M.INVENTORY_PICKUP = 'INVENTORY_PICKUP'
M.INVENTORY_DROP = 'INVENTORY_DROP'
M.INVENTORY_TOGGLE = 'INVENTORY_TOGGLE'
M.PASSIVE_SKILLS_TREE_TOGGLE = 'PASSIVE_SKILLS_TREE_TOGGLE'

M.EQUIPMENT_SWAP = 'EQUIPMENT_SWAP'
M.EQUIPMENT_CHANGE = 'EQUIPMENT_CHANGE'
M.EQUIPMENT_UNEQUIP = 'EQUIPMENT_UNEQUIP'

M.PLAYER_HEAL_SOURCE_ADD = 'PLAYER_HEAL_SOURCE_ADD'
--[[
  {
    amount = NUMBER,
    source = STRING,
    duration = NUMBER,
    property = STRING,
    maxProperty = STRING
  }
]]

M.PLAYER_HEAL_SOURCE_REMOVE = 'PLAYER_HEAL_SOURCE_REMOVE'
--[[ STRING ]]

M.PLAYER_USE_SKILL = 'PLAYER_USE_SKILL'
--[[ STRING ]]

M.PLAYER_DISABLE_ABILITIES = 'PLAYER_DISABLE_ABILITIES'
--[[
  BOOLEAN

  Disables/enables clicks for the player. This is used for situations where
  the player is trying to pick up an item and it shouldn't attack while picking it up.
]]

M.NOTIFIER_NEW_EVENT = 'NOTIFIER_NEW_EVENT'

return M