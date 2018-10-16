local bitser = require 'modules.bitser'
local path = require 'modules.file-system.path'

function saveFile(rootPath, saveId, data, metadata)
  local _, errors = pcall(function()
    local saveFolder = path.getSaveDirectory(rootPath, saveId)
    local folderExists = love.filesystem.getInfo(saveFolder)
    if (not folderExists) then
      love.filesystem.createDirectory(saveFolder)
    end
    bitser.dumpLoveFile(path.getMetadataPath(rootPath, saveId), metadata)
    bitser.dumpLoveFile(
      path.getSavedStatePath(rootPath, saveId),
      data
    )
  end)
  if errors then
    love.thread.getChannel('saveStateError'):push(errors)
  else
    love.thread.getChannel('saveStateSuccess'):push(true)
  end
end

function deleteSaveFile(rootPath, saveId)
  local ok, errors = pcall(function()
    local removeFile = require 'modules.file-system.remove-file'
    removeFile(
      path.getSaveDirectory(rootPath, saveId)
    )
    local success = not love.filesystem.getInfo(
      path.getSaveDirectory(rootPath, saveId)
    )
  end)
  if (not ok) then
    love.thread.getChannel('saveStateDeleteError'):push(errors)
  else
    love.thread.getChannel('saveStateDeleteSuccess'):push(true)
  end
end

local actionHandlers = {
  SAVE_STATE = saveFile,
  SAVE_STATE_DELETE = deleteSaveFile
}

local function observeThread()
  local message = love.thread.getChannel('DISK_IO'):demand()
  message = bitser.loads(message)
  local handler = actionHandlers[message.action]
  if (not handler) then
    error('invalid action '..message.action)
  end
  handler(unpack(message.payload))
  observeThread()
end
observeThread()