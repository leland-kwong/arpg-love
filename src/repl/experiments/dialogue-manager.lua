local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'

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

local Conversation = dynamicRequire 'repl.components.conversation'

Component.create({
  id = 'dialogueExample',
  group = 'firstLayer',
  init = function(self)
    local GuiText = require 'components.gui.gui-text'
    self.guiText = GuiText.create({
      font = require 'components.font'.primary.font
    }):setParent(self)

    local conversation = Conversation:new(conversations)
    self.conversation = conversation

    local function endConversation()
      conversation:continue('conversation_goodbye')
    end

    conversation:continue('conversation_1')

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
          conversation:continue('conversation_1')
        end

        local isOptionSelect = tonumber(msg.key)
        if isOptionSelect then
          -- select option
          local optionId = tonumber(msg.key)
          local success = conversation:selectOption(optionId)
          if (not success) then
            msgBus.send('PLAYER_ACTION_ERROR', 'invalid option '..optionId..' selected')
          end
        end

        if hotKeys.CONTINUE_CONVO == msg.key then
          if (not self.conversation:get()) then
            conversation:continue('conversation_1')
          elseif (#self.conversation:get().options == 0) then
            conversation:continue()
          end
        end
      end)
    }
  end,
  update = function(self)
    local isNewConvo = self.previousConvo ~= self.conversation
    if isNewConvo and (self.conversation:get()) then
        -- print(
        --   Inspect(
        --     self.conversation:get()
        --   )
        -- )
    end
    self.previousConvo = self.conversation
  end,
  draw = function(self)
    if (self.conversation:get()) then
      local nextScript = self.conversation:get()
      self.guiText:addf({{1,1,1}, nextScript.text}, 200, 'left', 150, 100)

      -- handle options
      local options = nextScript.options
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