local collisionWorlds = require 'components.collision-worlds'

local M = {}

local vw, vh = love.graphics.getWidth(), love.graphics.getHeight()
local dc = 100 -- distance from edge of screen
function M.isOutOfScreen(x, y)
  local screenX, screenY = x,y
  -- local screenX, screenY = love.graphics.transformPoint( x, y )
  return screenX < 0 - dc or
    screenX > vw + dc or
    screenY < 0 - dc or
    screenY > vh + dc
end

return M