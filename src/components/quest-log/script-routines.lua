local msgBus = require 'components.msg-bus'
local EventLog = require 'modules.log-db.events-log'
local definitions = require 'components.quest-log.quest-definitions'
local F = require 'utils.functional'
local globalState = require 'main.global-state'

local function getNextQuest(questList)
  return F.find(questList, function(questId)
    local log = EventLog.read(
      globalState.gameState:getId()
    )
    local questFromLog = log.quests[questId]
    if (not questFromLog) then
      return true
    end
    local isQuestCompleted = F.reduce(questFromLog.subTasks, function(numCompleted, task)
      return numCompleted + (task.completed and 1 or 0)
    end, 0) == #questFromLog.subTasks

    return not isQuestCompleted
  end)
end

local function isActiveQuest(questId)
  local log = EventLog.read(globalState.gameState:getId())
  return log.quests[questId] ~= nil
end

return {
    getNextQuest = getNextQuest,
    isActiveQuest = isActiveQuest,
    create = function(questList)
      return function()
        local nextScript
        local nextQuest
        local actions = {}

        actions.acceptQuest = function()
          local time = os.time()
          -- add new quest to log
          local quest = definitions[nextQuest]
          local questId = nextQuest
          msgBus.send('QUEST_ADD', {
            title = quest.title,
            id = questId,
            --[[
              subTask.props {
                id = STRING,
                description = LOVE2D_FORMATTED_STRING,
                completed = BOOL,
              }
            ]]
            subTasks = quest.subTasks,
          })
          nextScript = nil
        end

        actions.closeChat = function()
          nextScript = nil
        end

        actions.rejectQuest = actions.closeChat

        msgBus.on('NPC_CHAT_ACTION', function(msg)
          actions[msg.action]()
        end)

        nextQuest = getNextQuest(questList)
        nextScript = nextQuest and definitions[nextQuest].script

        while true do
          coroutine.yield(nextScript)
        end
      end
    end
  }