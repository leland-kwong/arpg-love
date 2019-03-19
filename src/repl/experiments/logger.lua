local dynamicRequire = require 'utils.dynamic-require'
local O = dynamicRequire 'utils.object-utils'
local Observable = require 'modules.observable'
local Log = require 'modules.log-db'
local F = require 'utils.functional'

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

test(
  'mergedLog',
  function()
    -- Log.tail(logPath, function(entry)
    --   entryHandlers[entry.type](finalLog, entry)
    -- end)

    -- local tick = require 'utils.tick'
    -- tick.recur(function()
    --   for i=1, 20 do
    --     Observable.all(
    --       Log.append(logPath, {
    --         type = entryTypes.ENEMY_KILL,
    --         id = 'e1',
    --       })
    --       ,Log.append(logPath, {
    --         type = entryTypes.ENEMY_KILL,
    --         id = 'e1'
    --       })
    --       ,Log.append(logPath, {
    --         type = entryTypes.ENEMY_KILL,
    --         id = 'e1'
    --       })
    --       ,Log.append(logPath, {
    --         type = entryTypes.ITEM_ACQUIRE,
    --         id = 'CHAIN_LIGHTNING'
    --       })
    --       ,Log.append(logPath, {
    --         type = entryTypes.ITEM_ACQUIRE,
    --         id = 'HAMMER_TIME'
    --       })
    --     ):next(function()
    --     end, function(err)
    --       print(err)
    --     end)
    --   end
    -- end, 1/60)

    -- tick.recur(function()
    --   print(
    --     Inspect(finalLog)
    --   )
    -- end, 1)
  end
)