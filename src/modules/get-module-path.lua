local memoize = require 'utils.memoize'

return memoize(function(file)
  local normalizedPath = string.gsub(file, '%.', '/')
  local fullPath = (not string.find(normalizedPath, '%.lua')) and
    (normalizedPath..'.lua') or
    normalizedPath
  local info = love.filesystem.getInfo(fullPath)
  -- default to init.lua if we can't find the file
  if (not info) then
    local initPath = normalizedPath..'/init.lua'
    local info = love.filesystem.getInfo(initPath)
    if info and info.type == 'file' then
      fullPath = initPath
    else
      return nil
    end
  end

  return fullPath
end)