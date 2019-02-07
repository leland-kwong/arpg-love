local bitser = require 'modules.bitser'
local String = require 'utils.string'
local dynamicRequire = require 'utils.dynamic-require'
local O = dynamicRequire 'utils.object-utils'
local Observable = require 'modules.observable'
local msgBus = require 'components.msg-bus'

local logDelimiter = '[[/LOG/]]'
local escapeSpecials = function(char)
  return '%'..char
end
local logDelimiterSplitPattern = string.gsub(logDelimiter, '[^a-zA-Z0-9]', escapeSpecials)

if (not logAppendThread) then
  -- start async write thread
  local source = love.filesystem.read('modules/log-db/async-write.lua')
  logAppendThread = love.thread.newThread(source)
  logAppendThread:start()
end

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

  local serialized = bitser.dumps(entry)
  assert(string.find(serialized, logDelimiter) == nil, 'log entry data has a log separator string fragment. The separator is '..logDelimiter)

  threadSend(
    'APPEND',
    path,
    serialized..logDelimiter
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
    local ok, result = pcall(function()
      local message = readChannel:pop()
      if message then
        if message == 'done' then
          onComplete(seed)
          return msgBus.CLEANUP
        end

        local String = require 'utils.string'
        local entries = String.split(message, logDelimiterSplitPattern)
        for i=1, (#entries) - 1 do
          local data = entries[i]
          local deserialized = bitser.loads(data)
          seed = onData(seed, deserialized)
        end
      end
    end)

    if (not ok) then
      onError(result)
      return
    end

    return result
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