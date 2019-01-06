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
    --[[
      SCHEMA

      local Enum = require 'utils.enum'
      local entryTypes = Enum({
        'ENEMY_KILL',
        'ITEM_ACQUIRE'
      })
      local entrySchema = {
        type = entryTypes,
        data = {
          id = id -- string
        }
      }

      local finalLog = {
        enemiesKilled = {
          [enemyId] = killCount
        },
        itemsAcquired = {
          [itemId] = acquiredCount
        }
      }
    ]]

    local entryTypes = {
      ENEMY_KILL = 1,
      ITEM_ACQUIRE = 2
    }

    local srcDir = love.filesystem.getWorkingDirectory()
    local json = require 'lua_modules.json'
    local F = require 'utils.functional'
    local dbData = json.decode(
      love.filesystem.read('enemies.cdb')
    )
    local enemyData = F.reduce(
      F.find(dbData.sheets, function(sheet)
        return sheet.name == 'enemies'
      end).lines,
      function(data, enemy)
        data[enemy.id] = enemy
        return data
      end,
      {}
    )

    local finalLog = {
      enemiesKilled = {},
      itemsAcquired = {}
    }

    local entryHandlers = {
      [entryTypes.ENEMY_KILL] = function(finalLog, entry)
        local curValue = finalLog.enemiesKilled[entry.id] or 0
        finalLog.enemiesKilled[entry.id] = curValue + 1
      end,
      [entryTypes.ITEM_ACQUIRE] = function(finalLog, entry)
        local curValue = finalLog.itemsAcquired[entry.id] or 0
        finalLog.itemsAcquired[entry.id] = curValue + 1
      end
    }

    local logPath = 'test/merged-log.log'
    Log.delete(logPath)

    local ts = Time()
    local entryCount = 0
    Log.readStream(logPath, function(_, entry)
      entryCount = entryCount + 1
      entryHandlers[entry.type](finalLog, entry)
    end, nil, function()
      print(
        Inspect({
          finalLog = finalLog,
          executionTime = Time() - ts,
          entryCount = entryCount
        })
      )
    end)

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