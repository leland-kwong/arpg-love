local bitser = require 'modules.bitser'
local String = require 'utils.string'
local dynamicRequire = require 'utils.dynamic-require'
local O = dynamicRequire 'utils.object-utils'
local Observable = require 'modules.observable'

local logSeparator = '___LOG___\n'

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

function Log.append(path, entry)
  local channel = love.thread.getChannel('ASYNC_WRITE_TEST')
  channel:push('APPEND')
  channel:push(path)
  channel:push(
    bitser.dumps(entry)..logSeparator
  )

  return Observable(function()
    local errorMsg = love.thread.getChannel('logAppendError'):pop()
    if errorMsg then
      return true, nil, errorMsg
    end

    local success = love.thread.getChannel('logAppendSuccess'):pop()
    if success then
      return true, true
    end
  end)
end

local function parseLog(log)
  return coroutine.wrap(function()
    if (not log) then
      return
    end
    local entries = String.split(log, logSeparator)
    -- skip the last one since it is empty
    for i=1, (#entries) - 1 do
      coroutine.yield(
        bitser.loads(entries[i])
      )
    end
  end)
end

function Log.load(path)
  return parseLog(
    love.filesystem.read(path)
  )
end

function Log.delete(path)
  love.filesystem.remove(path)
end

function Log.reduce(path, callback, seed)
  for entry in Log.load(path) do
    seed = callback(seed, entry)
  end
  return seed
end

local function reduceToFile(fromPath, toPath, callback, seed)
  local result = Log.reduce(fromPath, callback, seed)
  return love.filesystem.write(
    toPath,
    bitser.dumps(result)
  )
end

local Test = {
  setup = function(options)
    local noop = function() end

    options = options or {}
    options.beforeEach = options.beforeEach or noop
    options.afterEach = options.afterEach or noop

    return function(description, testFn)
      options.beforeEach()
      testFn()
      options.afterEach()
    end
  end
}

local logPath = 'test/log/log.log'
local test = Test.setup({
  beforeEach = function()
    -- Log.delete(logPath)
  end
})

local function readLog()
  local channel = love.thread.getChannel('ASYNC_WRITE_TEST')
  channel:push('READ')
  channel:push(logPath)
  channel:push('')
  Observable(function()
    local logString = love.thread.getChannel('logRead'):pop()
    if logString then
      return true, logString
    end
  end)
    :next(function(logString)
      print('\n\n')
      print(logString)
    end, function(err)
      print(err)
    end)
end

test(
  'append',
  function()
    local tick = require 'utils.tick'
    tick.recur(function()
      local entry = { foo = 'bar\n\n'..os.clock() }
      Log.append(logPath, entry)
        :next(function()
          -- Log.delete(logPath)

          -- assert(
          --   love.filesystem.read(logPath) == (bitser.dumps(entry)..logSeparator),
          --   'log append failed'
          -- )
          readLog()
        end, function(err)
          print(err)
        end)
        :next(nil, function(err)
          print(err)
        end)
    end, 1)
  end
)

-- test(
--   'load',
--   function()
--     local entries = {
--       'foo',
--       'bar'
--     }
--     for i=1, #entries do
--       Log.append(logPath, entries[i])
--     end
--     local logIterator = Log.load(logPath)

--     local loadedLog = {}
--     for entry in logIterator do
--       table.insert(loadedLog, entry)
--     end

--     assert(O.deepEqual(entries, loadedLog), 'log load failed')
--   end
-- )

-- test(
--   'delete',
--   function()
--     Log.append(logPath, 'foo')
--     Log.delete(logPath)
--     assert(love.filesystem.read(logPath) == nil, 'log delete fail')
--   end
-- )

-- test(
--   'reduce',
--   function()
--     local entries = {
--       {
--         foo = 'foo'
--       },
--       {
--         bar = 'bar'
--       }
--     }

--     for _,entry in ipairs(entries) do
--       Log.append(logPath, entry)
--     end

--     local reducedLog = Log.reduce(
--       logPath,
--       function(finalLog, entry)
--         return O.extend(finalLog, entry)
--       end,
--       {}
--     )

--     assert(
--       O.deepEqual({
--         foo = 'foo',
--         bar = 'bar'
--       }, reducedLog),
--       'log reduce failure'
--     )
--   end
-- )

-- test(
--   'reduce to single file',
--   function()
--     local entries = {
--       'foobar',
--       'bazcux'
--     }
--     for _,entry in ipairs(entries) do
--       Log.append(logPath, entry)
--     end

--     local pathToSaveTo = 'test/log/reduced-log.data'
--     reduceToFile(
--       logPath,
--       pathToSaveTo,
--       function(result, entry)
--         result = result..entry
--         return result
--       end,
--       ''
--     )

--     assert(
--       entries[1]..entries[2] ==
--       bitser.loads(
--         love.filesystem.read(pathToSaveTo)
--       ),
--       'reduce log to a single file failure'
--     )
--   end
-- )