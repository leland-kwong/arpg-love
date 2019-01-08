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
      itemsAcquired = {},
      quests = {}
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
    local enemyType = entry.data.type
    local curValue = finalLog.enemiesKilled[enemyType] or 0
    finalLog.enemiesKilled[enemyType] = curValue + 1
  end,
  ITEM_ACQUIRE = function(finalLog, entry)
    local itemType = entry.data.type
    local curValue = finalLog.itemsAcquired[enemyType] or 0
    finalLog.itemsAcquired[enemyType] = curValue + 1
  end,
  QUEST_NEW = function(finalLog, entry)
    local ok, err = pcall(function()
      finalLog.quests[entry.data.id] = entry.data
    end)

    if (not ok) then
      msgBus.send('LOG_ERROR', err)
    end
  end,
  QUEST_COMPLETE = function(finalLog, entry)
    local ok, err = pcall(function()
      finalLog.quests[entry.data.id].completed = true
    end)

    if (not ok) then
      msgBus.send('LOG_ERROR', err)
    end
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

local function setupListeners(self)
  return {
    msgBus.on('QUEST_NEW', function(msg)
      Log.append(gameId, {
        event = 'QUEST_NEW',
        data = {
          id = msg.questId,
          title = msg.title,
          description = msg.description,
          completed = false
        }
      })
    end),
    msgBus.on('QUEST_COMPLETE', function(msg)
      Log.append(gameId, {
        event = 'QUEST_COMPLETE',
        data = {
          id = msg.questId
        }
      })
    end),
    msgBus.on('ENEMY_DESTROYED', function(msg)
      local isEnemy = msg.parent.class == 'enemyAi'
      if isEnemy then
        Log.append(gameId, {
          event = 'ENEMY_KILL',
          data = {
            type = msg.parent.type
          }
        })
      end
    end)
  }
end

function EventLog.start(gameId)
  Component.create({
    id = 'EventLog',
    init = function(self)
      Component.addToGroup(self, 'firstLayer')

      self.cleanupTailLog = Log.tail(gameId, function(entry)
        print(
          Inspect(entry)
        )
        updateInMemoryLog(gameId, entry)
      end)

      self.listeners = setupListeners(self)
    end,
    final = function(self)
      if self.cleanupTailLog then
        self.cleanupTailLog()
      end
      msgBus.off(self.listeners)
    end
  })
end

function EventLog.read(gameId)
  return getCompactedLog(gameId)
end

return EventLog