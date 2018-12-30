local bitser = require 'modules.bitser'
local path = require 'modules.file-system.path'

function saveFile(file, data)
  local _, errors = pcall(function()
    bitser.dumpLoveFile(
      file,
      data
    )
  end)
  if errors then
    love.thread.getChannel('saveStateError'):push(errors)
    return errors
  else
    love.thread.getChannel('saveStateSuccess'):push(true)
  end
end

function deleteFile(file)
  local ok, errors = pcall(function()
    return love.filesystem.remove(file)
  end)
  if (not ok) then
    love.thread.getChannel('saveStateDeleteError'):push(errors)
  else
    love.thread.getChannel('saveStateDeleteSuccess'):push(true)
  end
end

local actionHandlers = {
  SAVE_STATE = saveFile,
  SAVE_STATE_DELETE = deleteFile
}

local function observeThread()
  local message = love.thread.getChannel('DISK_IO'):demand()
  message = bitser.loads(message)
  local action, payload, data = message[1], message[2], message[3]
  local handler = actionHandlers[action]
  if (not handler) then
    error('invalid action '..action)
  end
  handler(payload, data)
  observeThread()
end
observeThread()