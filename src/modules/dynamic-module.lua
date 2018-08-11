local noop = require'utils.noop'

return function(path)
  local chunk = love.filesystem.load(path)
  if chunk then
    return chunk()
  end
  print('module not found: `'..path..'`')
  return noop
end