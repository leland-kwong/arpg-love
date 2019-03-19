-- can load lua modules with or without the '.lua' extension
return function(rootPath, filename)
  local errorFree, loadedItem = pcall(function()
    local fullPath = rootPath .. '.' .. string.sub(filename, string.find(filename, '[^%.]*'))
    return require(fullPath)
  end)
  return errorFree, loadedItem
end