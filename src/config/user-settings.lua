--[[
  TODO:
  * Save user settings to disk when settings have been updated
  * Function for updating user settings. This is so that we can automatically update settings when they are changed.
]]

-- user configurable settings

local M = {}

M.keyboard = {
  UP = 'w',
  RIGHT = 'd',
  DOWN = 's',
  LEFT = 'a',
  SKILL_1 = '3',
  SKILL_2 = '4',
  SKILL_3 = 'q',
  SKILL_4 = 'e',
  ACTIVE_ITEM_1 = '1',
  ACTIVE_ITEM_2 = '2',
  MOVE_BOOST = 'space',
  INVENTORY_TOGGLE = 'i',
  MAIN_MENU = 'escape',
  PORTAL_OPEN = 't',
  PAUSE_GAME = 'p',
  MUSIC_TOGGLE = 'm'
}

M.mouseInputMap = {
  SKILL_1 = 1,
  SKILL_2 = 2,
  SKILL_3 = 3,
  SKILL4 = 4
}

M.mouseClickDelay = 0.12
M.keyPressedDelay = 0.03 -- minimum time that should elapse to trigger a key press event

M.camera = {
  speed = 0.4, -- lerp duration (larger value means slower movement)
}

M.sound = {
  musicEnabled = false,
  musicVolume = 0.5
}

return M