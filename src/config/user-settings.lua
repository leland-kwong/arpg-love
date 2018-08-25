-- user configurable settings

local M = {}

M.isDebug = true
M.collisionDebug = false

M.keyboard = {
  UP = 'w',
  RIGHT = 'd',
  DOWN = 's',
  LEFT = 'a',
  SKILL_1 = '3',
  SKILL_2 = '4',
  SKILL_3 = 'e',
  SKILL_4 = 'r',
  ACTIVE_ITEM_1 = '1',
  ACTIVE_ITEM_2 = '2',
  INVENTORY_TOGGLE = 'i',
  MAIN_MENU = 'escape'
}

M.mouseInputMap = {
  SKILL_1 = 1,
  SKILL_2 = 2,
  SKILL_3 = 3,
  SKILL4 = 4
}

M.camera = {
  speed = 0.3 -- lerp duration (larger value means slower movement)
}

return M