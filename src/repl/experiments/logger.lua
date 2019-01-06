local bitser = require 'modules.bitser'
local String = require 'utils.string'
local dynamicRequire = require 'utils.dynamic-require'
local O = dynamicRequire 'utils.object-utils'
local Observable = require 'modules.observable'

local logSeparator = '___LOG___'

local Component = require 'modules.component'
Component.create({
  id = 'logger-init',
  init = function(self)
    if (not logAppendThread) then
      -- start async write thread
      local source = love.filesystem.read('repl/async-write.lua')
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
    local count = readChannel:getCount()
    local done = false
    while (not done) do
      local message = readChannel:pop()
      if message == 'done' then
        done = true
        onComplete(seed)
        return msgBus.CLEANUP
      else
        if message then
          seed = onData(seed, bitser.loads(message))
        else
          done = true
        end
      end
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

local Test = {
  setup = function(options)
    local noop = function() end

    options = options or {}
    options.beforeEach = options.beforeEach or noop
    options.afterEach = options.afterEach or noop

    return function(description, testFn)
      options.beforeEach(testFn)
      options.afterEach()
    end
  end
}

local test = Test.setup({
  beforeEach = function(onReady)
    onReady()
  end
})

test(
  'append',
  function()
    local logPath = 'test/log-append.log'
    Log.delete(logPath)
    local data = { foo = 'bar\n\n'..os.clock() }
    Log.append(logPath, data)
      :next(function()
        Log.readStream(logPath, function(entries, entry)
          table.insert(entries, entry)
          return entries
        end, nil, function(entries)
          assert(O.deepEqual(data, entries[1]), 'log append fail')
        end, {})
      end, function(err)
        print(err)
      end)
      :next(nil, function(err)
        print(err)
      end)
  end
)

test(
  'delete',
  function()
    local function handleError(err)
      print(err)
    end

    local logPath = 'test/log-delete.log'
    Log.delete(logPath)
    Log.append(logPath, 'foo')
      :next(function()
        Log.delete(logPath)
          :next(function()
            Log.readStream(logPath, function(entries, entry)
              table.insert(entries, entry)
              return entries
            end, nil, function(entries)
              assert(#entries == 0, 'log delete fail')
            end, {})
          end, handleError)
      end, handleError)
  end
)

test(
  'readStream',
  function()
    local entries = {
      {
        foo = 'foo'
      },
      {
        bar = 'bar'
      }
    }
    local logPath = 'test/log-read-stream.log'
    Log.delete(logPath)
    local F = require 'utils.functional'
    Observable.all(
      F.map(entries, function(entry)
        return Log.append(logPath, entry)
      end)
    ):next(function()
      Log.readStream(logPath, function(newEntries, entry)
        table.insert(newEntries, entry)
        return newEntries
      end, nil, function(newEntries)
        assert(O.deepEqual(entries, newEntries))
      end, {})
    end, function(err)
      print(err)
    end)
  end
)