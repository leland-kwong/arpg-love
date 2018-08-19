-- global game configuration

local f = require 'utils.functional'
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

local xpDiff = 20
M.levelExperienceRequirements = {}
-- setup level experience requirements
(function()
  local req = M.levelExperienceRequirements
  for level=1, 3 do
    table.insert(
      req,
      (level^2+level)/2*xpDiff-(level*xpDiff)
    )
  end
end)()

M.gridSize = 16
M.scaleFactor = 2
M.resolution = {
  w = 640,
  h = 360
}

return M