local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'

local conversationMt = {
  text = '',
  options = {} -- list of conversation options
}
conversationMt.__index = conversationMt

local dialogueRoutine = function(dialogue)
  return coroutine.create(function()
    for i=1, #dialogue do
      coroutine.yield(
        setmetatable(dialogue[i], conversationMt)
      )
    end
  end)
end

local function giveExperienceAction(exp)
  return {
    action = 'giveReward',
    data = {
      experience = exp
    }
  }
end

local conversations = {
  conversation_1 = {
    {
      actionOnly = true,
      actions = {
        giveExperienceAction(100)
      }
    },
    {
      text = 'Hello fellow space traveler...'
    },
    {
      text = 'Choose a path:',
      options = {
        {
          label = 'What items you got?',
          actions = {
            {
              action = 'nextConversation',
              data = {
                id = 'conversation_2'
              }
            }
          }
        },
        {
          label = 'What quests you got?',
          actions = {
            {
              action = 'nextConversation',
              data = {
                id = 'conversation_3'
              }
            }
          }
        },
        {
          label = 'Claim reward test',
          actions = {
            giveExperienceAction(100)
          }
        }
      },
    },
  },

  conversation_2 = {
    {
      text = 'Choose a reward:',
      options = {
        {
          label = 'sickass ring',
          actions = {
            {
              action = 'giveReward',
              data = {
                item = 'sickass ring'
              }
            },
            {
              action = 'nextConversation',
              data = {
                id = 'conversation_2_choice_1'
              }
            }
          },
        },
        {
          label = 'cool boots',
          actions = {
            {
              action = 'giveReward',
              data = {
                item = 'cool boots'
              }
            },
            {
              action = 'nextConversation',
              data = {
                id = 'conversation_2_choice_2'
              }
            }
          },
        }
      }
    }
  },
  conversation_2_choice_1 = {
    {
      text = 'Sickass ring eh? Fine choice!'
    }
  },
  conversation_2_choice_2 = {
    {
      text = 'Cool boots eh? Fine choice!'
    }
  },

  conversation_3 = {
    {
      text = 'Here are some quests for ya:',
      options = {
        {
          label = 'Kill minibots',
          actions = {
            {
              action = 'giveQuest',
              data = {
                id = 'killMinibots',
                count = 5
              }
            }
          }
        },
        {
          label = 'Kill slimes',
          actions = {
            {
              action = 'giveQuest',
              data = {
                id = 'killSlimes',
                count = 5
              }
            }
          }
        }
      }
    }
  },

  conversation_goodbye = {
    { text = 'See ya.' }
  }
}

Component.create({
  id = 'dialogueExample',
  group = 'firstLayer',
  init = function(self)
    local GuiText = require 'components.gui.gui-text'
    self.guiText = GuiText.create({
      font = require 'components.font'.primary.font
    }):setParent(self)

    local function startConversation(self, conversation)
      self.conversate = dialogueRoutine(conversation)
      local _, nextScript = coroutine.resume(self.conversate)

      self.nextScript = nextScript
    end

    local actions = {
      nextConversation = function(data)
        startConversation(self, conversations[data.id])
      end,
      giveReward = function(reward)
        print(
          'give reward!\n',
          Inspect(reward)
        )
      end,
      giveQuest = function(quest)
        print(
          'give quest!\n',
          Inspect(quest)
        )
      end
    }

    local function execActions(actionsList)
      for i=1, #actionsList do
        local a = actionsList[i]
        actions[a.action](a.data)
      end
    end

    local function continueConversation(conversationId)
      if conversationId then
        actions.nextConversation({ id = conversationId })
      else
        local isAlive, nextScript = coroutine.resume(self.conversate)
        self.nextScript = nextScript
      end
      if self.nextScript and self.nextScript.actionOnly then
        execActions(self.nextScript.actions)
        continueConversation()
      end
    end

    local function endConversation()
      actions.nextConversation({
        id = 'conversation_goodbye'
      })
    end

    continueConversation('conversation_1')

    self.listeners = {
      msgBus.on('KEY_PRESSED', function(msg)
        local hotKeys = {
          RESTART_CONVO = 'r',
          CONTINUE_CONVO = 'return',
          END_CONVO = 'e'
        }

        if hotKeys.END_CONVO == msg.key then
          endConversation()
        end

        if hotKeys.RESTART_CONVO == msg.key then
          continueConversation('conversation_1')
        end

        local isOptionSelect = tonumber(msg.key)
        if isOptionSelect then
          local options = self.nextScript.options
          -- select option
          local optionId = tonumber(msg.key)
          local option = options[optionId]
          if option then
            continueConversation()
            execActions(option.actions)
          else
            msgBus.send('PLAYER_ACTION_ERROR', 'invalid option '..optionId..' selected')
          end
        end

        if hotKeys.CONTINUE_CONVO == msg.key then
          if (not self.nextScript) then
            continueConversation('conversation_1')
          elseif (#self.nextScript.options == 0) then
            continueConversation()
          end
        end
      end)
    }
  end,
  update = function(self)
    local isNewScript = self.previousScript ~= self.nextScript
    if isNewScript and self.nextScript then
        print(self.nextScript.text)
    end
    self.previousScript = self.nextScript
  end,
  draw = function(self)
    if self.nextScript then
      self.guiText:addf({{1,1,1}, self.nextScript.text}, 200, 'left', 150, 100)

      -- handle options
      local options = self.nextScript.options
      local w, h = self.guiText:getSize()
      local lineHeight = 20
      for i=1, #options do
        local o = options[i]
        local optionsText = {
          {1,1,0}, i..'. ',
          {1,1,1}, o.label
        }
        self.guiText:addf(optionsText, 200, 'left', 150, 100 + (lineHeight * i))
      end
    end
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})