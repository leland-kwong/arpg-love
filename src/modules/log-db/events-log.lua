local Log = require 'modules.log-db'
local msgBus = require 'components.msg-bus'
local Component = require 'modules.component'
local Db = require 'modules.database'
local O = require 'utils.object-utils'

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
      quests = {},
      checkPointsUnlocked = {
        ['1-1'] = true
      }
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
  QUEST_ADD = function(finalLog, entry)
    local ok, err = pcall(function()
      finalLog.quests[entry.data.id] = entry.data
    end)

    if (not ok) then
      msgBus.send('LOG_ERROR', err)
    end
  end,
  QUEST_TASK_UPDATE = function(finalLog, entry)
    local ok, err = pcall(function()
      local quest = finalLog.quests[entry.data.questId]
      local nextState = entry.data.nextState
      local F = require 'utils.functional'
      local O = require 'utils.object-utils'
      local newSubTasksState = F.map(quest.subTasks, function(task)
        local isTaskToComplete = task.id == entry.data.taskId
        if isTaskToComplete then
          return O.assign({}, task, {
            state = nextState
          })
        end
        return task
      end)
      quest.subTasks = newSubTasksState
    end)

    if (not ok) then
      msgBus.send('LOG_ERROR', err)
    end
  end,
  QUEST_TASK_COMPLETE = function(finalLog, entry)
    local ok, err = pcall(function()
      local quest = finalLog.quests[entry.data.questId]
      local F = require 'utils.functional'
      local O = require 'utils.object-utils'
      local newSubTasksState = F.map(quest.subTasks, function(task)
        local isTaskToComplete = task.id == entry.data.taskId
        if isTaskToComplete then
          return O.assign({}, task, {
            completed = true
          })
        end
        return task
      end)
      quest.subTasks = newSubTasksState
    end)

    if (not ok) then
      msgBus.send('LOG_ERROR', err)
    end
  end,
  CHECKPOINT_UNLOCKED = function(log, entry)
    local checkPointId = entry.data
    log.checkPointsUnlocked = O.assign({}, log.checkPointsUnlocked, {
      [checkPointId] = true
    })
  end,
  EVENT_LOG_UPDATE = function(log, entry)
    O.assign(log, entry.data)
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
  done = true
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

local function setupListeners(self, gameId)
  local function handleAppendError(err)
    msgBus.send('LOG_ERROR', err)
  end

  return {
    -- [[NOTE: this should only be used for development purposes]]
    msgBus.on('EVENT_LOG_UPDATE', function(nextState)
      assert(_DEVELOPMENT_, '`EVENT_LOG_UPDATE` may only be used during development')
      Log.append(gameId, {
        event = 'EVENT_LOG_UPDATE',
        data = nextState
      })
    end),
    msgBus.on('QUEST_ADD', function(msg)
      Log.append(gameId, {
        event = 'QUEST_ADD',
        data = msg
      }):next(nil, handleAppendError)
    end),
    msgBus.on('QUEST_TASK_UPDATE', function(msg)
      Log.append(gameId, {
        event = 'QUEST_TASK_UPDATE',
        data = msg
      })
    end),
    msgBus.on('QUEST_TASK_COMPLETE', function(msg)
      Log.append(gameId, {
        event = 'QUEST_TASK_COMPLETE',
        data = {
          questId = msg.questId,
          taskId = msg.taskId
        }
      }):next(nil, handleAppendError)
    end),
    msgBus.on('ENEMY_DESTROYED', function(msg)
      local isEnemy = msg.parent.class == 'enemyAi'
      if isEnemy then
        Log.append(gameId, {
          event = 'ENEMY_KILL',
          data = {
            type = msg.parent.type
          }
        }):next(nil, handleAppendError)
      end
    end),
    msgBus.on('CHECKPOINT_UNLOCKED', function(checkPointId)
      print(checkPointId)
      Log.append(gameId, {
        event = 'CHECKPOINT_UNLOCKED',
        data = checkPointId
      })
    end)
  }
end

function EventLog.start(gameId)
  if (not gameId) then
    print('[EVENT LOG] invalid gameId ', gameId)
    return
  end

  Component.create({
    id = 'EventLog',
    init = function(self)
      Component.addToGroup(self, 'firstLayer')
      self.cleanupTailLog = Log.tail(gameId, function(entry)
        updateInMemoryLog(gameId, entry)
      end)

      self.listeners = setupListeners(self, gameId)
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
  assert(gameId ~= nil, '[EventLog.read] invalid game id')
  return getCompactedLog(gameId)
end

function EventLog.cleanup(gameId)
  local Observable = require 'modules.observable'
  return Observable.all({
    Db.load('saved-states'):delete(eventLogDbKey(gameId)),
    Log.delete(gameId)
  })
end

return EventLog