--[[
  NOTE: On certain situations, loading a file more than once can cause the game to lock up.
  This issue cannot be reliably replicated. One solution that seems to have worked well is to
  cache the loaded data and not load the file again if it has been already loaded from disk.
]]

--[[
  TODO: add support for multiple fileSystem instances so that we can save to different
  subdirectories with their own save settings.
]]

local f = require 'utils.functional'
local bitser = require 'modules.bitser'
local config = require 'config.config'
local path = require 'modules.file-system.path'
local Observable = require 'modules.observable'

local fileSystem = {}
local fileListCache = nil
local function invalidateFileListCache()
  fileListCache = nil
end

local loadedFilesCache = {}
local function invalidateLoadedFileCache(file)
  loadedFilesCache[file] = nil
end

local function init()
  -- start async write thread
  local source = love.filesystem.read('modules/file-system/async-write.lua')
  local thread = love.thread.newThread(source)
  thread:start()
end

init()

local function checkRootPath(rootPath)
  assert(type(rootPath) == 'string', 'invalid rootPath')
end

-- saves file in the background for non-blocking io
function fileSystem.saveFile(rootPath, saveId, saveState, metadata)
  checkRootPath(rootPath)
  local serializedState = bitser.dumps(saveState)
  local message = bitser.dumps({
    action = 'SAVE_STATE',
    payload = {
      rootPath,
      saveId,
      serializedState,
      metadata
    }
  })
  love.thread.getChannel('DISK_IO')
    :push(message)

  return Observable(function()
    local errorMsg = love.thread.getChannel('saveStateError'):pop()
    if errorMsg then
      return true, nil, errorMsg
    end

    local success = love.thread.getChannel('saveStateSuccess'):pop()
    if success then
      local filePath = path.getSavedStatePath(rootPath, saveId)
      invalidateLoadedFileCache(filePath)
      invalidateFileListCache()
      return true
    end
  end)
end

function fileSystem.deleteFile(rootPath, saveId)
  checkRootPath(rootPath)
  local message = bitser.dumps({
    action = 'SAVE_STATE_DELETE',
    payload = {
      rootPath,
      saveId
    }
  })
  love.thread.getChannel('DISK_IO')
    :push(message)

  return Observable(function()
    local errorMsg = love.thread.getChannel('saveStateDeleteError'):pop()
    if errorMsg then
      return true, nil, errorMsg
    end

    local success = love.thread.getChannel('saveStateDeleteSuccess'):pop()
    if success then
      local filePath = path.getSavedStatePath(rootPath, saveId)
      invalidateLoadedFileCache(filePath)
      invalidateFileListCache()
      return true
    end
  end)
end

function fileSystem.loadSaveFile(rootPath, saveId)
  checkRootPath(rootPath)
  local filePath = path.getSavedStatePath(rootPath, saveId)

  local loadedFile = loadedFilesCache[filePath]
  if loadedFile then
    print('load cached')
    return loadedFile
  end

  print('load uncached')

  local ok, result = pcall(function()
    return bitser.loads(
      bitser.loadLoveFile(filePath)
    )
  end)

  if ok then
    loadedFilesCache[filePath] = result
  end

  return result, ok
end

function fileSystem.listSavedFiles(rootPath)
  if (not fileListCache) then
    checkRootPath(rootPath)
    local saves = love.filesystem.getDirectoryItems(rootPath)
    fileListCache = f.map(saves, function(saveId)
      return {
        id = saveId,
        metadata = bitser.loadLoveFile(path.getMetadataPath(rootPath, saveId))
      }
    end)
  end
  return fileListCache
end

return fileSystem