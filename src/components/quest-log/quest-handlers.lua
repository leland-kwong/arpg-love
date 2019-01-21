local Component = require 'modules.component'
local EventLog = require 'modules.log-db.events-log'

local function getGameId()
  local globalState = require 'main.global-state'
  return globalState.gameState:getId()
end

local function getTaskState(questId, taskId)
  local log = EventLog.read(getGameId())
  local F = require 'utils.functional'
  local quest = log.quests[questId]
  local task = F.find(quest.subTasks, function(t)
    return t.id == taskId
  end)
  return task.state or {}
end

local requirementHandlers = {
  --[[
    props {
      count = {
        [{enemyType1} STRING] = {count} NUMBER
      },
      time = NUMBER
    }
  ]]
  killEnemy = function(requirements, questId, taskId)
    local msgBus = require 'components.msg-bus'

    Component.create({
      id = questId..'__'..taskId,
      init = function(self)
        Component.addToGroup(self, 'questHandlers')

        self.listeners = {
          msgBus.on('ENEMY_DESTROYED', function(msg)
            local ok, err = pcall(function()
              local enemyType = msg.parent.type
              if requirements.count[enemyType] then
                local state = getTaskState(questId, taskId)
                local O = require 'utils.object-utils'
                local killEnemyState = state.killEnemy or {
                  count = {}
                }
                O.assign(killEnemyState.count, {
                  [enemyType] = (killEnemyState.count[enemyType] or 0) + 1
                })
                local nextState = O.assign({}, state, {
                  killEnemy = killEnemyState
                })

                msgBus.send('QUEST_TASK_UPDATE', {
                  questId = questId,
                  taskId = taskId,
                  nextState = nextState
                })

                local isTaskCompleted = O.deepEqual(nextState.killEnemy, requirements)
                if isTaskCompleted then
                  msgBus.send('QUEST_TASK_COMPLETE', {
                    questId = questId,
                    taskId = taskId
                  })
                end
              end
            end)
            if (not ok) then
              msgBus.send('LOG_ERROR', err)
            end
          end)
        }
      end,
      final = function(self)
        msgBus.off(self.listeners)
      end
    })
  end,
  --[[
    props {
      types = {
        [{itemType} STRING] = {count} NUMBER
      },
      timeLimit = NUMBER
    }
  ]]
  acquireItems = function(props)
  end,
  --[[
    props {
      types = {
        [{locationType} STRING] = {count} NUMBER
      },
      timeLimit = NUMBER
    }
  ]]
  visitHotSpots = function(props)
  end
}

return {
  start = function()
    Component.create({
      id = 'questDefinitions',
      init = function(self)
        Component.addToGroup(self, 'all')
        self.activeTasks = {}
      end,
      update = function(self, dt)
        local log = EventLog.read(getGameId())
        for _,q in pairs(log.quests) do
          for _,t in ipairs(q.subTasks) do
            local Grid = require 'utils.grid'
            if (not Grid.get(self.activeTasks, q.id, t.id)) then
              Grid.set(self.activeTasks, q.id, t.id, true)

              for name,props in pairs(t.requirements) do
                local initFn = requirementHandlers[name]
                initFn(props, q.id, t.id)
              end
            end
          end
        end
      end,
      final = function()
        for _,entity in pairs(Component.groups.questHandlers.getAll()) do
          entity:delete(true)
        end
      end
    })
  end
}