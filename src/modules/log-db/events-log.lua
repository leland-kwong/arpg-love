local Log = require 'modules.log-db'
local msgBus = require 'components.msg-bus'
local Component = require 'modules.component'
local Db = require 'modules.database'

local EventLog = {}

local activeLog

local function eventLogDbKey(gameId)
  return gameId..'/event-log'
end

local function getCompactedLog(gameId)
  local db = Db.load('saved-states')
  local inMemoryLog = db:get(eventLogDbKey(gameId))
  if (not inMemoryLog) then
    local defaultLog = {
      enemiesKilled = {},
      itemsAcquired = {}
    }
    db:put(eventLogDbKey(gameId), defaultLog)
    inMemoryLog = defaultLog
  end
  return inMemoryLog
end

local function saveCompactedLogToDisk(gameId)
  local db = Db.load('saved-states')
  return db:put(eventLogDbKey(gameId), getCompactedLog(gameId))
end

local entryHandlers = {
  ENEMY_KILL = function(finalLog, entry)
    local curValue = finalLog.enemiesKilled[entry.type] or 0
    finalLog.enemiesKilled[entry.type] = curValue + 1
  end,
  ITEM_ACQUIRE = function(finalLog, entry)
    local curValue = finalLog.itemsAcquired[entry.type] or 0
    finalLog.itemsAcquired[entry.type] = curValue + 1
  end
}

local function updateInMemoryLog(gameId, entry)
  local finalLog = getCompactedLog(gameId)
  entryHandlers[entry.event](finalLog, entry)
end

function EventLog.compact(gameId)
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

  local done = false
  local errMsg
  local handleError = function(err)
    done = true
    errMsg = err
  end
  Log.readStream(gameId, function(_, entry)
    updateInMemoryLog(gameId, entry)
  end, handleError, function()
    saveCompactedLogToDisk(gameId)
      :next(function()
        Log.delete(gameId)
          :next(function()
            done = true
          end, handleError)
      end, handleError)
  end)

  local Observable = require 'modules.observable'
  return Observable(function()
    return done, (not errMsg), errMsg
  end)
end

function EventLog.start(gameId)
  Component.create({
    id = 'EventLog',
    init = function(self)
      Component.addToGroup(self, 'firstLayer')

      self.cleanupTailLog = Log.tail(gameId, function(entry)
        updateInMemoryLog(gameId, entry)

        print(
          Inspect(
            getCompactedLog(gameId)
          )
        )
      end)

      self.listeners = {
        msgBus.on('ENEMY_DESTROYED', function(msg)
          local isEnemy = msg.parent.class == 'enemyAi'
          if isEnemy then
            Log.append(gameId, {
              event = 'ENEMY_KILL',
              type = msg.parent.type
            })
          end
        end)
      }
    end,
    final = function(self)
      if self.cleanupTailLog then
        self.cleanupTailLog()
      end
      msgBus.off(self.listeners)
    end
  })
end

return EventLog