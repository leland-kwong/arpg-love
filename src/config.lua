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

local xpDiff = 20
M.levelExperienceRequirements = {}
-- setup level experience requirements
(function()
  local req = M.levelExperienceRequirements
  for level=1, 99 do
    table.insert(
      req,
      (level^2+level)/2*xpDiff-(level*xpDiff)
    )
  end
end)()

M.gridSize = 16
M.scaleFactor = 2
M.resolution = {
  w = 640 * 1.5,
  h = 360 * 1.5
}

return M