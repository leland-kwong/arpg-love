local Component = require 'modules.component'
local dynamicRequire = require 'utils.dynamic-require'
local QuestLog = dynamicRequire('components.hud.quest-log')
local Conversation = dynamicRequire 'repl.components.conversation'
local msgBus = require 'components.msg-bus'

local convos = require 'repl.shared.conversations'

local log = dynamicRequire 'repl.shared.quest-log'

local questRequirementHandlers = {
  killEnemy = function(props, taskId)
    -- print('kill enemy intialized', taskId)
  end,

  npcInteract = function(props, taskId)
    local msgBus = require 'components.msg-bus'
    -- print('npc interact initialized', taskId)
    msgBus.on('NPC_INTERACT', function(msg)
      if msg.npcName == props.npcName then
        msgBus.send('QUEST_TASK_COMPLETED', { id = taskId })
      end
    end)
  end
}

Component.create({
  id = 'questHandler',
  log = log,
  init = function(self)
    Component.addToGroup(self, 'all')
    self.activeTasks = {}
  end,
  update = function(self, dt)
    -- initialize any new task requirements
    local completedTasks = self.log.completedTasks
    for questId,q in pairs(self.log.quests) do
      for i=1, #q.subTasks do
        local t = q.subTasks[i]
        local taskCompleted = completedTasks[t.id]
        if (
          (not taskCompleted) and
          (not self.activeTasks[t.id])
        ) then
          self.activeTasks[t.id] = true

          for name,props in pairs(t.requirements) do
            local initFn = questRequirementHandlers[name]
            initFn(props, t.id)
          end
        end
      end
    end
  end,
  draw = function(self)
  end,
  final = function()
    for _,entity in pairs(Component.groups.questHandlers.getAll()) do
      entity:delete(true)
    end
  end
})

Component.create({
  id = 'questManager',
  init = function(self)
    Component.addToGroup(self, 'system')
    self.questLog = QuestLog.create({
      id = 'QuestLog',
      x = 100,
      y = 100,
      width = 160,
      height = 200,
    })
    self.log = log

    local GuiText = require 'components.gui.gui-text'
    self.guiText = GuiText.create({
      font = require 'components.font'.primary.font
    }):setParent(self)

    self.conversation = Conversation:new(convos)
    self.conversation:set('something_lurking')

    self.listeners = {
      msgBus.on('QUEST_TASK_COMPLETED', function(msg)
        self.log.completedTasks[msg.id] = true
      end),

      -- msgBus.on('INTERACT_ENVIRONMENT_OBJECT', function()
      --   return true
      -- end)
    }
  end,
  update = function(self)
    self.questLog.log = self.log

    if self.log.completedTasks['quest_2_1'] then
      self.conversation:setIfDifferent('something_lurking_finished')
      self.conversation:resume()
    end

    local nextScript = self.conversation:get()
    local isNewScript = self.previousScript ~= nextScript
    if nextScript then
      print(nextScript.text)
    end
    self.previousScript = nextScript
  end,
  draw = function(self)

  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})