-- global game configuration

local M = {}

M.isDebug = true
M.collisionDebug = false

M.keyboard = {
  UP = 'w',
  RIGHT = 'd',
  DOWN = 's',
  LEFT = 'a',
  SKILL_1 = 'space',
  SKILL_2 = 'shift',
  INVENTORY_TOGGLE = 'i',
  EXIT_GAME = 'escape'
}

M.mouseInputMap = {
  SKILL_1 = 1,
  SKILL_2 = 2
}

M.gridSize = 16
M.scaleFactor = 2
M.resolution = {
  w = 640,
  h = 360
}

return M