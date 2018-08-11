local config = require'config'

return function()
  local res = config.resolution
  love.graphics.print('Dev mode paused', res.w / 2, res.h / 2)
end