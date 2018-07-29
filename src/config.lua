local M = {}

M.isDebug = true
M.collisionDebug = false

M.keyboard = {
  UP = 'w',
  RIGHT = 'd',
  DOWN = 's',
  LEFT = 'a',
  SKILL_1 = 'space'
}

M.mouseInputMap = {
  SKILL_1 = 1,
  SKILL_2 = 2
}

local w,h = 640, 360
M.scaleFactor = 2
love.window.setMode(w * M.scaleFactor, h * M.scaleFactor)

return M