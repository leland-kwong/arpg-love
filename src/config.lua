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

local base = 2
M.levelExperienceRequirements = {
  0,
	base * 1,
	base * 2,
	base * 3.5,
	base * 6,
	base * 9,
	base * 14,
	base * 20,
	base * 300,
	base * 1000,
}

M.gridSize = 16
M.scaleFactor = 2
M.resolution = {
  w = 640,
  h = 360
}

return M