
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

local function startConversation(self, conversation)
  self.conversate = dialogueRoutine(conversation)
  local _, nextScript = coroutine.resume(self.conversate)

  self.nextScript = nextScript
end

local Conversation = {
  new = function(self, conversationMap)

    local actions = {
      nextConversation = function(self, data)
        startConversation(self, conversationMap[data.id])
      end,
      giveReward = function(_, reward)
        print(
          'give reward!\n',
          Inspect(reward)
        )
      end,
      giveQuest = function(_, quest)
        print(
          'give quest!\n',
          Inspect(quest)
        )
      end
    }

    local execActions = function(self, actionsList)
      for i=1, #actionsList do
        local a = actionsList[i]
        actions[a.action](self, a.data)
      end
    end

    local c = {
      nextScript = nil,

      continue = function(self, conversationId)
        if conversationId then
          actions.nextConversation(self, { id = conversationId })
        else
          local isAlive, nextScript = coroutine.resume(self.conversate)
          self.nextScript = nextScript
        end
        if self.nextScript and self.nextScript.actionOnly then
          execActions(self, self.nextScript.actions)
          self:continue()
        end
      end,

      -- returns option selection success
      selectOption = function(self, optionNumber)
        if (self:isDone()) then
          return false
        end

        local options = self.nextScript.options
        local o = options[optionNumber]
        if o then
          -- self:continue()
          execActions(self, o.actions)
          return true
        end

        return false
      end,

      get = function(self)
        -- a nil value means no script exists
        return self.nextScript
      end,

      isDone = function(self)
        return self.nextScript == nil
      end
    }

    return c
  end,
}

return Conversation