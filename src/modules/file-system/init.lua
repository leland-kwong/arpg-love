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
      return true
    end
  end)
end

function fileSystem.loadSaveFile(rootPath, saveId)
  checkRootPath(rootPath)
  local ok, result = pcall(function()
    return bitser.loads(
      bitser.loadLoveFile(
        path.getSavedStatePath(rootPath, saveId)
      )
    )
  end)
  if (not ok) then
    return error(result)
  end
  return result
end

function fileSystem.listSavedFiles(rootPath)
  checkRootPath(rootPath)
  local saves = love.filesystem.getDirectoryItems(rootPath)
  return f.map(saves, function(saveId)
    return {
      id = saveId,
      metadata = bitser.loadLoveFile(path.getMetadataPath(rootPath, saveId))
    }
  end)
end

if config.isDebug then
  require 'modules.file-system.test'(fileSystem)
end

return fileSystem