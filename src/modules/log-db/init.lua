local bitser = require 'modules.bitser'
local String = require 'utils.string'
local dynamicRequire = require 'utils.dynamic-require'
local O = dynamicRequire 'utils.object-utils'
local Observable = require 'modules.observable'
local msgBus = require 'components.msg-bus'

local logSeparator = '_LOG_'

local Component = require 'modules.component'
Component.create({
  id = 'logger-init',
  init = function(self)
    if (not logAppendThread) then
      -- start async write thread
      local source = love.filesystem.read('modules/log-db/async-write.lua')
      logAppendThread = love.thread.newThread(source)
      logAppendThread:start()
    end
  end,
})

local Log = {}

local mainChannel = love.thread.getChannel('ASYNC_WRITE_TEST')
local function threadSend(action, a, b)
  mainChannel:push(action)
  mainChannel:push(a)
  mainChannel:push(b == nil and '' or b)
end

function Log.append(path, entry)
  assert(
    type(path) == 'string',
    'invalid path'
  )

  threadSend(
    'APPEND',
    path,
    bitser.dumps(entry)..logSeparator
  )

  return Observable(function()
    local channel = love.thread.getChannel('logAppend')
    if channel:getCount() > 0 then
      local success = channel:pop()
      local err = (not success) and 'log append error'

      if success then
        msgBus.send('logTail.'..path, entry)
      end

      return true, success, err
    end
  end)
end

function Log.readStream(path, onData, onError, onComplete, seed)
  local noop = require 'utils.noop'
  onData = onData or noop
  onError = onError or noop
  onComplete = onComplete or noop

  threadSend(
    'READ',
    path
  )

  local readChannel = love.thread.getChannel('logRead.'..path)
  local msgBus = require 'components.msg-bus'
  msgBus.on('UPDATE', function()
    local ok, err = pcall(function()
      local message = readChannel:pop()
      if message then
        local String = require 'utils.string'
        local entries = String.split(message, logSeparator)
        for i=1, (#entries) - 1 do
          local data = entries[i]
          seed = onData(seed, bitser.loads(data))
        end
        onComplete(seed)
        return msgBus.CLEANUP
      end
    end)

    if (not ok) then
      onError(err)
    end
  end)
end

function Log.delete(path)
  threadSend(
    'DELETE',
    path
  )

  return Observable(function()
    local channel = love.thread.getChannel('logDelete')
    local success = channel:pop()
    if success ~= nil then
      if success then
        return true, true
      end
      return true, false, 'log delete error'
    end
  end)
end

function Log.tail(path, onData, onError)
  assert(type(path) == 'string', 'invalid `path`')
  assert(type(onData) == 'function', '`onData` must be a function')

  local listener = msgBus.on('logTail.'..path, onData)

  local function close()
    msgBus.off(listener)
  end
  return close
end

return Log