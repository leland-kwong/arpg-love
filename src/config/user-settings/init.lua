--[[
  TODO:
  * Save user settings to disk when settings have been updated
  * Function for updating user settings. This is so that we can automatically update settings when they are changed.
]]

-- user configurable settings

local M = {}

M.keyboard = {
  MOVE_UP = 'w',
  MOVE_RIGHT = 'd',
  MOVE_DOWN = 's',
  MOVE_LEFT = 'a',
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
  PASSIVE_SKILLS_TREE_TOGGLE = 'o'
}

-- these actions may not be remapped
M.keyboardFixedActions = {
  MAIN_MENU = true
}

M.mouseInputMap = {
  SKILL_1 = 1,
  SKILL_2 = 2,
  SKILL_3 = 3,
  SKILL_4 = 4
}

M.mouseClickDelay = 0.12
M.keyPressedDelay = 0.03 -- minimum time that should elapse to trigger a key press event

M.camera = {
  speed = 0.4, -- lerp duration (larger value means slower movement)
}

M.sound = {
  masterVolume = 1,
  musicVolume = 0.5
}

M.isDevelopment = false
M.previousVersion = nil -- the last version the game was loaded as

return M