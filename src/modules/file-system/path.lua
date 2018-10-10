local M = {}

function M.getSaveDirectory(rootPath, saveId)
  return rootPath..'/'..saveId
end

function M.getSavedStatePath(rootPath, saveId)
  return M.getSaveDirectory(rootPath, saveId)..'/save-state.save'
end

function M.getMetadataPath(rootPath, saveId)
  return M.getSaveDirectory(rootPath, saveId)..'/metadata.dat'
end

return M