--[[
  takes a path from a tiled object property and converts it to a requireable path
]]

local function readTiledFileProperty(path)
  if (not path) then
    return nil
  end

  local normalizedPath = string.gsub(
    string.gsub(path, '%.%.%/',''),
    '%/', '.'
  )
  return require(
    string.gsub(normalizedPath, '%.lua', '')
  )
end

return readTiledFileProperty